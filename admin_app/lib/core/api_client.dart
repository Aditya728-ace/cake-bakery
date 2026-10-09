import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Talks to the FastAPI backend. Tokens live in the OS keystore (never in plain prefs),
/// and an expired access token is refreshed transparently once per request.
class ApiClient {
  ApiClient({this.onSessionExpired});

  final void Function()? onSessionExpired;
  final _storage = const FlutterSecureStorage();
  String? _access;
  String? _refresh;

  bool get hasSession => _refresh != null;

  Future<void> load() async {
    _access = await _storage.read(key: 'access');
    _refresh = await _storage.read(key: 'refresh');
  }

  Future<void> saveTokens(Map<String, dynamic> j) async {
    _access = j['access_token'] as String;
    _refresh = j['refresh_token'] as String;
    await _storage.write(key: 'access', value: _access);
    await _storage.write(key: 'refresh', value: _refresh);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
  }

  Uri _uri(String path) => Uri.parse('$apiBase$path');

  Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (_access != null) 'Authorization': 'Bearer $_access',
      };

  Future<dynamic> get(String path) => _send(() => http.get(_uri(path), headers: _headers()));

  Future<dynamic> post(String path, [Object? body, bool auth = true]) =>
      _send(() => http.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})), auth: auth);

  Future<dynamic> put(String path, Object body) =>
      _send(() => http.put(_uri(path), headers: _headers(), body: jsonEncode(body)));

  Future<dynamic> patch(String path, Object body) =>
      _send(() => http.patch(_uri(path), headers: _headers(), body: jsonEncode(body)));

  Future<dynamic> delete(String path) => _send(() => http.delete(_uri(path), headers: _headers()));

  /// Multipart upload of one or many image files under the form field [field].
  Future<dynamic> upload(String path, String field, List<String> filePaths) => _send(() async {
        final req = http.MultipartRequest('POST', _uri(path));
        req.headers.addAll(_headers(json: false));
        for (final p in filePaths) {
          req.files.add(await http.MultipartFile.fromPath(field, p));
        }
        return http.Response.fromStream(await req.send());
      }, timeout: const Duration(seconds: 120));

  Future<dynamic> _send(Future<http.Response> Function() call,
      {bool auth = true, bool retry = true, Duration timeout = const Duration(seconds: 30)}) async {
    http.Response res;
    try {
      res = await call().timeout(timeout);
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    } catch (_) {
      throw ApiException('Cannot reach the server. Check your internet connection.');
    }
    if (res.statusCode == 401 && auth && retry && _refresh != null) {
      if (await _tryRefresh()) return _send(call, auth: auth, retry: false, timeout: timeout);
      await clear();
      onSessionExpired?.call();
      throw ApiException('Your session has expired. Please sign in again.', 401);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    throw ApiException(_message(res), res.statusCode);
  }

  Future<bool> _tryRefresh() async {
    try {
      final res = await http
          .post(_uri('/api/auth/refresh'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh_token': _refresh}))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return false;
      await saveTokens(jsonDecode(res.body) as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _message(http.Response r) {
    try {
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      final d = body['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty) {
        return d.map((e) {
          final loc = (e['loc'] is List && (e['loc'] as List).isNotEmpty) ? (e['loc'] as List).last.toString() : '';
          final msg = (e['msg'] ?? 'Invalid value').toString().replaceFirst('Value error, ', '');
          return loc.isEmpty ? msg : '$loc: $msg';
        }).join('\n');
      }
    } catch (_) {}
    return 'Something went wrong (${r.statusCode}). Please try again.';
  }
}
