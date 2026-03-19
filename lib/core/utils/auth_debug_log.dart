import 'dart:async';

import 'package:flutter/foundation.dart';

/// Simple in-memory log buffer for auth debug messages.
///
/// - Usable from any layer (no Riverpod dependency).
/// - Broadcasts changes via [stream] so UI can react.
/// - Calls [debugPrint] as well, so logs appear in the console.
/// - No-op in release builds (guarded by [kDebugMode]).
class AuthDebugLog {
  AuthDebugLog._();

  static final StreamController<List<String>> _controller =
      StreamController<List<String>>.broadcast();

  static final List<String> _lines = [];

  /// Live stream of all buffered lines (replays current state on listen).
  static Stream<List<String>> get stream => _controller.stream;

  /// Current snapshot of buffered lines.
  static List<String> get lines => List.unmodifiable(_lines);

  /// Append a log line. Timestamped as HH:mm:ss.mmm.
  static void add(String message) {
    if (!kDebugMode) return;
    final now = DateTime.now();
    final ts =
        '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}.${_three(now.millisecond)}';
    final line = '[$ts] $message';
    _lines.add(line);
    _controller.add(List.unmodifiable(_lines));
    debugPrint('[AuthLog] $message');
  }

  /// Clear the buffer.
  static void clear() {
    _lines.clear();
    _controller.add([]);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _three(int n) => n.toString().padLeft(3, '0');
}
