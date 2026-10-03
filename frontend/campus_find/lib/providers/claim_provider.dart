import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/claim.dart';
import '../services/api_service.dart';

/// Handles the signed-in user's own claims.
class ClaimProvider extends ChangeNotifier {
  final ApiService api;
  ClaimProvider({required this.api});

  List<Claim> _claims = [];
  bool _loading = false;
  String? _error;

  List<Claim> get claims => _claims;
  bool get loading => _loading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<bool> submitClaim({
    required String itemId,
    required String reason,
    String? verificationAnswer,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await api.post('/items/$itemId/claim', body: {
        'reason': reason,
        if (verificationAnswer != null && verificationAnswer.isNotEmpty)
          'verificationAnswer': verificationAnswer,
      });
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<List<Claim>> fetchMyClaims() async {
    _setLoading(true);
    _error = null;
    try {
      final res = await api.get('/my-claims');
      _claims = (res['data']['claims'] as List)
          .map((e) => Claim.fromJson(e as Map<String, dynamic>))
          .toList();
      _setLoading(false);
      return _claims;
    } on ApiException catch (e) {
      _error = e.message;
      _claims = [];
      _setLoading(false);
      return [];
    }
  }
}
