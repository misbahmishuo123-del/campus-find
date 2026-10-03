import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService api;
  final AuthService storage;

  AuthProvider({required this.api, required this.storage});

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAdmin => _user?.isAdmin ?? false;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Called once at startup: if a token exists, validate it via /auth/me.
  Future<void> restoreSession() async {
    final token = await storage.readToken();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    api.setToken(token);
    try {
      final res = await api.get('/auth/me');
      _user = AppUser.fromJson(res['data']['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } on ApiException {
      await storage.clear();
      api.setToken(null);
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await api.post('/auth/login',
          body: {'email': email.trim(), 'password': password});
      final token = res['data']['token'] as String;
      api.setToken(token);
      await storage.saveToken(token);
      _user = AppUser.fromJson(res['data']['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? department,
  }) async {
    _setLoading(true);
    try {
      final res = await api.post('/auth/register', body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
        if (department != null && department.isNotEmpty)
          'department': department.trim(),
      });
      final token = res['data']['token'] as String;
      api.setToken(token);
      await storage.saveToken(token);
      _user = AppUser.fromJson(res['data']['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await storage.clear();
    api.setToken(null);
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
