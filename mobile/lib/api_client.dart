import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status; // 0 => tarmoq xatosi
  final String message;
  @override
  String toString() => message;
}

class TokenStore {
  final _s = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> get access async {
    try {
      return await _s.read(key: 'access');
    } catch (_) {
      return null;
    }
  }

  Future<String?> get refresh async {
    try {
      return await _s.read(key: 'refresh');
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String a, String r) async {
    try {
      await _s.write(key: 'access', value: a);
      await _s.write(key: 'refresh', value: r);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _s.delete(key: 'access');
      await _s.delete(key: 'refresh');
    } catch (_) {}
  }

  Future<String?> get theme async {
    try {
      return await _s.read(key: 'theme');
    } catch (_) {
      return null;
    }
  }

  Future<void> setTheme(String v) async {
    try {
      await _s.write(key: 'theme', value: v);
    } catch (_) {}
  }

  Future<bool> get onboarded async {
    try {
      return (await _s.read(key: 'onboarded')) == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> setOnboarded() async {
    try {
      await _s.write(key: 'onboarded', value: '1');
    } catch (_) {}
  }
}

class ApiClient {
  ApiClient(this.tokens, {String? baseUrl}) : baseUrl = baseUrl ?? kApiBaseUrl;
  final String baseUrl;
  final TokenStore tokens;
  void Function()? onSessionExpired;
  Future<bool>? _refreshing;

  static const _netError = "Internet yoki serverga ulanishda xatolik. Ulanishni tekshirib qayta urinib ko'ring.";

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body, Map<String, String>? headers, bool auth = true}) =>
      _send('POST', path, body: body, headers: headers, auth: auth);
  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', path, body: body);
  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);
  Future<dynamic> delete(String path, {Object? body}) => _send('DELETE', path, body: body);

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? query, Object? body, Map<String, String>? headers, bool auth = true, bool retried = false}) async {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null) q[k] = v.toString();
    });
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: q.isEmpty ? null : q);
    final req = http.Request(method, uri);
    req.headers['Content-Type'] = 'application/json; charset=utf-8';
    req.headers['Accept'] = 'application/json';
    if (headers != null) req.headers.addAll(headers);
    if (auth) {
      final t = await tokens.access;
      if (t != null) req.headers['Authorization'] = 'Bearer $t';
    }
    if (body != null) req.body = jsonEncode(body);

    late http.Response res;
    try {
      res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 60)));
    } on TimeoutException {
      throw ApiException(0, _netError);
    } on Exception {
      throw ApiException(0, _netError);
    }

    if (res.statusCode == 401 && auth && !retried) {
      if (await _refresh()) {
        return _send(method, path, query: query, body: body, headers: headers, auth: auth, retried: true);
      }
      onSessionExpired?.call();
      throw ApiException(401, "Sessiya muddati tugadi. Qayta kiring.");
    }
    if (res.statusCode >= 400) throw ApiException(res.statusCode, _detail(res));
    if (res.statusCode == 204 || res.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  String _detail(http.Response res) {
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      final d = j is Map ? j['detail'] : null;
      if (d is String) return d;
      if (d is List && d.isNotEmpty && d.first is Map) return (d.first as Map)['msg'].toString();
    } catch (_) {}
    return res.statusCode >= 500 ? "Serverda xatolik. Keyinroq urinib ko'ring." : "So'rov bajarilmadi (${res.statusCode})";
  }

  Future<bool> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final r = await tokens.refresh;
    if (r == null) return false;
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/auth/refresh'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh_token': r}))
          .timeout(const Duration(seconds: 45));
      if (res.statusCode != 200) return false;
      final j = jsonDecode(res.body);
      await tokens.save(j['access_token'], j['refresh_token']);
      return true;
    } catch (_) {
      return false;
    }
  }
}
