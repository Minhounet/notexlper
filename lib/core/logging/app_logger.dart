import 'package:flutter/foundation.dart';

/// A single log entry captured by [AppLogger].
class LogEntry {
  final DateTime timestamp;
  final String message;

  /// The stringified exception, if any.
  final String? error;

  LogEntry({required this.timestamp, required this.message, this.error});
}

/// Lightweight in-memory logger.
///
/// Every entry is also printed via [debugPrint] so it shows up in the
/// IDE / flutter logs console. In production builds debugPrint is a no-op,
/// but the entries are still collected and can be viewed via [LogViewerPage].
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void log(String message, {Object? error, StackTrace? stackTrace}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      message: message,
      error: error?.toString(),
    );
    _entries.add(entry);
    debugPrint('[LOG] $message'
        '${error != null ? '\n  ↳ $error' : ''}'
        '${stackTrace != null ? '\n$stackTrace' : ''}');
    LogNotifier.instance.notify();
  }

  void clear() {
    _entries.clear();
    LogNotifier.instance.notify();
  }
}

/// A [ChangeNotifier] that fires whenever [AppLogger] records a new entry or
/// is cleared. Widgets can use a [ListenableBuilder] with this notifier to
/// reactively update (e.g. a badge on the log-viewer icon).
class LogNotifier extends ChangeNotifier {
  LogNotifier._();
  static final LogNotifier instance = LogNotifier._();

  void notify() => notifyListeners();
}
