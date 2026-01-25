import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.splashDuration = const Duration(seconds: 2),
    this.onInitialized,
  });

  final Duration splashDuration;
  final VoidCallback? onInitialized;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeApp() {
    _timer = Timer(widget.splashDuration, () {
      if (mounted) {
        widget.onInitialized?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 100,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: theme.colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
