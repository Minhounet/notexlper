import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';

/// In-app log viewer — shows all entries captured by [AppLogger].
/// Accessible from the home screen in dev mode via the bug icon.
class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  @override
  Widget build(BuildContext context) {
    final entries = AppLogger.instance.entries;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear logs',
              onPressed: () {
                AppLogger.instance.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 64),
                  SizedBox(height: 16),
                  Text('No errors logged'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // Show newest first.
                final entry = entries[entries.length - 1 - index];
                final hasError = entry.error != null;
                return _LogTile(entry: entry, theme: theme, hasError: hasError);
              },
            ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogEntry entry;
  final ThemeData theme;
  final bool hasError;

  const _LogTile({
    required this.entry,
    required this.theme,
    required this.hasError,
  });

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        final text = '${entry.message}\n${entry.error ?? ''}';
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.info_outline,
              size: 18,
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatTime(entry.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.error != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
