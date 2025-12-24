import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final FirestoreService _firestore;
  final NotificationService _localNotifications;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  StreamSubscription? _subscription;
  String? _currentUserId;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationController(this._firestore, this._localNotifications);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void listenToNotifications(String userId, {bool isAdmin = false}) {
    // Avoid re-subscribing if same user/role
    if (_currentUserId == userId && _subscription != null) return;

    _subscription?.cancel();
    _currentUserId = userId;

    Stream<List<NotificationModel>> stream;
    if (isAdmin) {
      stream = _firestore.getAdminNotifications();
    } else {
      stream = _firestore.getUserNotifications(userId);
    }

    _subscription = stream.listen((newList) {
      // Check for new notifications to trigger local alert
      // Strategy: Use top item creation time to detect new ones efficiently?
      // Or diff IDs.
      if (newList.isNotEmpty && _notifications.isNotEmpty) {
        // Simple check: if latest item in new list is newer than latest in old list
        // and not in old list.
        final latestNew = newList.first;
        final alreadyHasIt = _notifications.any((n) => n.id == latestNew.id);

        if (!alreadyHasIt) {
          // It's a new notification!
          _localNotifications.showNotification(
            id: latestNew.hashCode,
            title: latestNew.title,
            body: latestNew.body,
            payload: latestNew.relatedId,
          );
        }
      } else if (newList.isNotEmpty && _notifications.isEmpty) {
        // Initial load? Don't spam. But if app was closed and opened?
        // Maybe check isRead?
        // Let's only notify for UNREAD items on first load?
        // Or honestly, just silent on first load to avoid spamming user with 50 alerts.
      }

      _notifications = newList;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.markNotificationAsRead(notificationId);
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      // We can't modify the object since it's final, but the stream update will come soon.
      // Or we can replace it in local list for instant UI feedback.
      // Since Firestore is fast, let's rely on stream for simplicity,
      // or implement optimistic if needed.
    }
  }
}
