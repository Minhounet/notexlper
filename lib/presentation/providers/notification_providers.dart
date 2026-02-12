import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/fake_notification_service.dart';
import '../../domain/services/notification_service.dart';

/// Provides the notification service instance (singleton).
///
/// In dev mode, uses [FakeNotificationService] which logs to debug console.
/// In prod, replace with a real implementation using flutter_local_notifications.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return FakeNotificationService();
});
