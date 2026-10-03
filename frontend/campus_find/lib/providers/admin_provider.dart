import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/claim.dart';
import '../models/match_result.dart';
import '../services/api_service.dart';

class AdminClaimDetail {
  final Claim claim;
  final String? verificationQuestion;
  final bool? verificationMatched;
  final List<MatchResult> possibleMatches;

  AdminClaimDetail({
    required this.claim,
    required this.possibleMatches,
    this.verificationQuestion,
    this.verificationMatched,
  });
}

/// Admin-only operations: dashboard stats, claim review, marking returned.
class AdminProvider extends ChangeNotifier {
  final ApiService api;
  AdminProvider({required this.api});

  Map<String, dynamic>? _stats;
  List<Claim> _claims = [];
  AdminClaimDetail? _detail;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get stats => _stats;
  List<Claim> get claims => _claims;
  AdminClaimDetail? get detail => _detail;
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

  Future<void> fetchStats() async {
    _setLoading(true);
    try {
      final res = await api.get('/admin/stats');
      _stats = res['data'] as Map<String, dynamic>;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _setLoading(false);
  }

  Future<void> fetchClaims({String? status}) async {
    _setLoading(true);
    try {
      final res =
          await api.get('/admin/claims', query: {'status': status});
      _claims = (res['data']['claims'] as List)
          .map((e) => Claim.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      _claims = [];
    }
    _setLoading(false);
  }

  Future<AdminClaimDetail?> fetchClaimDetail(String claimId) async {
    _setLoading(true);
    _detail = null;
    try {
      final res = await api.get('/admin/claims/$claimId');
      final data = res['data'] as Map<String, dynamic>;
      _detail = AdminClaimDetail(
        claim: Claim.fromJson(data['claim'] as Map<String, dynamic>),
        verificationQuestion: data['verificationQuestion']?.toString(),
        verificationMatched: data['verificationMatched'] as bool?,
        possibleMatches: (data['possibleMatches'] as List? ?? [])
            .map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _setLoading(false);
    return _detail;
  }

  Future<bool> reviewClaim({
    required String claimId,
    required String status, // approved | rejected
    String? adminNotes,
  }) async {
    _setLoading(true);
    try {
      await api.patch('/admin/claims/$claimId',
          body: {'status': status, if (adminNotes != null) 'adminNotes': adminNotes});
      _error = null;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> markReturned(String itemId) async {
    _setLoading(true);
    try {
      await api.patch('/admin/items/$itemId/return', body: {});
      _error = null;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    }
  }
}
