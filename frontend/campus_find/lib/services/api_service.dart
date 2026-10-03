import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/api_exception.dart';

/// Thin REST client for the CampusFind backend.
/// Holds the JWT in memory and attaches it as a Bearer token to every request.
/// It never stores or knows about any secret other than the user's own token.
class ApiService {
  String? _token;
  final String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> _headers() {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    final qp = <String, String>{};
    query.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) qp[k] = v.toString();
    });
    return uri.replace(queryParameters: qp.isEmpty ? null : qp);
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    return _send(() => _client.get(_uri(path, query), headers: _headers()));
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    return _send(() => _client.post(_uri(path),
        headers: _headers(), body: jsonEncode(body ?? {})));
  }

  Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body}) async {
    return _send(() => _client.patch(_uri(path),
        headers: _headers(), body: jsonEncode(body ?? {})));
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _send(() => _client.delete(_uri(path), headers: _headers()));
  }

  Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 20));
    } on http.ClientException {
      throw ApiException('Network error while contacting the server.',
          statusCode: 0);
    } catch (_) {
      // Connection refused / DNS failure / timeout etc.
      throw ApiException(
          'Cannot reach the server. Check your connection and API_BASE_URL.',
          statusCode: 0);
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response (${response.statusCode}).',
          statusCode: response.statusCode);
    }

    final ok = response.statusCode >= 200 &&
        response.statusCode < 300 &&
        (json['success'] != false);

    if (!ok) {
      throw ApiException(
        json['message']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    return json;
  }
}
