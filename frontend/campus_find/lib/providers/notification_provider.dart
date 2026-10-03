import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService api;
  NotificationProvider({required this.api});

  List<AppNotification> _notifications = [];
  int _unread = 0;
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  int get unread => _unread;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> fetch() async {
    _setLoading(true);
    try {
      final res = await api.get('/notifications');
      _notifications = (res['data']['notifications'] as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      _unread = (res['data']['unread'] as num?)?.toInt() ?? 0;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _setLoading(false);
  }

  Future<void> markRead(String id) async {
    try {
      await api.patch('/notifications/$id/read', body: {});
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].read) {
        final old = _notifications[idx];
        _notifications[idx] = AppNotification(
          id: old.id,
          title: old.title,
          message: old.message,
          type: old.type,
          read: true,
          createdAt: old.createdAt,
          itemId: old.itemId,
          claimId: old.claimId,
        );
        if (_unread > 0) _unread--;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    try {
      await api.patch('/notifications/read-all', body: {});
      await fetch();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  void reset() {
    _notifications = [];
    _unread = 0;
    notifyListeners();
  }
}
