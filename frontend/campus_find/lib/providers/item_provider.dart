import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/item.dart';
import '../models/match_result.dart';
import '../services/api_service.dart';

class ItemProvider extends ChangeNotifier {
  final ApiService api;
  ItemProvider({required this.api});

  List<Item> _items = [];
  bool _loading = false;
  String? _error;

  List<Item> get items => _items;
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

  Future<List<Item>> fetchItems({Map<String, dynamic>? filters}) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await api.get('/items', query: filters);
      final list = (res['data']['items'] as List)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      _items = list;
      _setLoading(false);
      return list;
    } on ApiException catch (e) {
      _error = e.message;
      _items = [];
      _setLoading(false);
      return [];
    }
  }

  Future<Item?> fetchItem(String id) async {
    try {
      final res = await api.get('/items/$id');
      return Item.fromJson(res['data']['item'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<List<MatchResult>> fetchMatches(String id) async {
    try {
      final res = await api.get('/items/$id/matches');
      return (res['data']['matches'] as List)
          .map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return [];
    }
  }

  Future<List<Item>> fetchMyReports() async {
    _setLoading(true);
    _error = null;
    try {
      final res = await api.get('/my-reports');
      final list = (res['data']['items'] as List)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      _items = list;
      _setLoading(false);
      return list;
    } on ApiException catch (e) {
      _error = e.message;
      _items = [];
      _setLoading(false);
      return [];
    }
  }

  /// Returns the created item's id, or null on failure.
  Future<String?> createItem(Map<String, dynamic> payload) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await api.post('/items', body: payload);
      final item = Item.fromJson(res['data']['item'] as Map<String, dynamic>);
      _setLoading(false);
      return item.id;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return null;
    }
  }

  Future<bool> deleteItem(String id) async {
    _error = null;
    try {
      await api.delete('/items/$id');
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
