import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// Full-screen authentication page.
///
/// Shows two tabs: "Create Account" and "Sign In".
/// On success, calls [onAuthenticated] and the caller navigates to the app.
class AuthPage extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthPage({super.key, required this.onAuthenticated});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / icon
                Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Notexlper',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your personal checklist workspace',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: theme.colorScheme.onPrimary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(text: 'Create Account'),
                      Tab(text: 'Sign In'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Tab views
                SizedBox(
                  height: 320,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _AuthForm(
                        key: const ValueKey('create'),
                        mode: _AuthMode.create,
                        onAuthenticated: widget.onAuthenticated,
                      ),
                      _AuthForm(
                        key: const ValueKey('signin'),
                        mode: _AuthMode.signIn,
                        onAuthenticated: widget.onAuthenticated,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

enum _AuthMode { create, signIn }

class _AuthForm extends ConsumerStatefulWidget {
  final _AuthMode mode;
  final VoidCallback onAuthenticated;

  const _AuthForm({super.key, required this.mode, required this.onAuthenticated});

  @override
  ConsumerState<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<_AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isCreate => widget.mode == _AuthMode.create;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final notifier = ref.read(authProvider.notifier);

    final result = _isCreate
        ? await notifier.signUp(username, password, _rememberMe)
        : await notifier.signIn(username, password, _rememberMe);

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (_) => widget.onAuthenticated(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Username
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username is required';
              if (v.trim().length < 3) return 'At least 3 characters';
              if (v.trim().length > 30) return 'At most 30 characters';
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                return 'Only letters, numbers and underscores';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            textInputAction:
                _isCreate ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: _isCreate ? null : (_) => _submit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            },
          ),
          if (_isCreate) ...[
            const SizedBox(height: 12),
            // Confirm password
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 8),
          // Remember Me
          Row(
            children: [
              Switch(
                value: _rememberMe,
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _rememberMe = v),
              ),
              const SizedBox(width: 8),
              const Text('Remember me'),
            ],
          ),
          const SizedBox(height: 12),
          // Submit
          FilledButton(
            key: const Key('auth-submit-btn'),
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isCreate ? 'Create Account' : 'Sign In'),
          ),
        ],
      ),
    );
  }
}
