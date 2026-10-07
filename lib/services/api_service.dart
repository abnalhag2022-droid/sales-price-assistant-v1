import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  final bool isAuth;
  final bool isConflict;
  final bool isNetwork;

  ApiException(
    this.status,
    this.message, {
    this.isAuth = false,
    this.isConflict = false,
    this.isNetwork = false,
  });

  @override
  String toString() => 'API $status: $message';
}

class ApiService {
  final String baseUrl;
  final http.Client _client;
  AuthSession? _session;
  Future<void> Function(AuthSession session)? onSessionChanged;
  Future<void> Function()? onSessionRevoked;

  ApiService({
    String? baseUrl,
    http.Client? client,
    AuthSession? session,
  })  : baseUrl = (baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'http://10.0.2.2:8000',
                ))
            .replaceAll(RegExp(r'/$'), ''),
        _client = client ?? http.Client(),
        _session = session;

  AuthSession? get session => _session;

  set session(AuthSession? value) {
    _session = value;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_session?.accessToken.isNotEmpty == true)
          'Authorization': 'Bearer ${_session!.accessToken}',
      };

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    String? idempotencyKey,
    bool allowRefresh = true,
  }) async {
    if (allowRefresh && _session?.isExpired == true) {
      await refreshToken();
    }
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      ..._headers,
      if (idempotencyKey != null) 'X-Idempotency-Key': idempotencyKey,
    };
    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw StateError('Unsupported method $method');
      }
    } catch (e) {
      throw ApiException(0, 'تعذر الاتصال بالخادم: $e', isNetwork: true);
    }

    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }

    if (response.statusCode == 401 && allowRefresh && _session?.refreshToken != null) {
      final refreshed = await refreshToken(throwOnFailure: false);
      if (refreshed) {
        return _request(
          method,
          path,
          body: body,
          idempotencyKey: idempotencyKey,
          allowRefresh: false,
        );
      }
    }

    if (response.statusCode == 401) {
      await onSessionRevoked?.call();
      throw ApiException(401, 'انتهت صلاحية الجلسة', isAuth: true);
    }
    if (response.statusCode == 409) {
      throw ApiException(409, _message(data), isConflict: true);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _message(data));
    }
    return data;
  }

  Future<bool> health() async {
    try {
      await _request('GET', '/api/health', allowRefresh: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AuthSession> login(String username, String password) async {
    final data = await _request(
      'POST',
      '/api/auth/login',
      body: {'username': username, 'password': password},
      allowRefresh: false,
    );
    final session = _sessionFromLogin(data, username);
    _session = session;
    await onSessionChanged?.call(session);
    return session;
  }

  Future<bool> refreshToken({bool throwOnFailure = true}) async {
    final refresh = _session?.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final data = await _request(
        'POST',
        '/api/auth/refresh',
        body: {'refresh_token': refresh},
        allowRefresh: false,
      );
      final session = _sessionFromRefresh(data);
      _session = session;
      await onSessionChanged?.call(session);
      return true;
    } catch (e) {
      await onSessionRevoked?.call();
      if (throwOnFailure) rethrow;
      return false;
    }
  }

  Future<void> logout({bool revoke = true}) async {
    final refresh = _session?.refreshToken;
    if (revoke && refresh != null && refresh.isNotEmpty) {
      try {
        await _request(
          'POST',
          '/api/auth/logout',
          body: {'refresh_token': refresh},
          allowRefresh: false,
        );
      } catch (_) {
        // Local logout must always succeed even if the server is offline.
      }
    }
    _session = null;
    await onSessionRevoked?.call();
  }

  Future<List<Item>> items({String q = ''}) async {
    final data = await _request(
      'GET',
      '/api/items${q.isEmpty ? '' : '?q=${Uri.encodeQueryComponent(q)}'}',
    );
    return _list(data).map(Item.fromJson).toList();
  }

  Future<List<Customer>> customers() async {
    final data = await _request('GET', '/api/customers');
    return _list(data).map(Customer.fromJson).toList();
  }

  Future<List<PriceList>> priceLists() async {
    final data = await _request('GET', '/api/price-lists');
    return _list(data).map(PriceList.fromJson).toList();
  }

  Future<List<UserAccount>> users() async {
    final data = await _request('GET', '/api/users');
    return _list(data).map(UserAccount.fromJson).toList();
  }

  Future<Ticket> createSession(
    String customerId,
    String priceListId, {
    required String operationId,
    String? clientSessionId,
  }) async {
    final data = await _request(
      'POST',
      '/api/sessions',
      body: {
        'customer_id': customerId,
        'price_list_id': priceListId,
        if (clientSessionId != null) 'client_session_id': clientSessionId,
        'client_operation_id': operationId,
      },
      idempotencyKey: operationId,
    );
    return Ticket.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> addLine(
    String sessionId,
    TicketLine line, {
    required String operationId,
  }) async {
    await _request(
      'POST',
      '/api/sessions/$sessionId/items',
      body: {...line.toJson(), 'client_operation_id': operationId},
      idempotencyKey: operationId,
    );
  }

  Future<void> editLine(
    String sessionId,
    String itemCode,
    double qty,
    double price, {
    required String operationId,
  }) async {
    await _request(
      'PUT',
      '/api/sessions/$sessionId/items/$itemCode',
      body: {'qty': qty, 'price': price, 'client_operation_id': operationId},
      idempotencyKey: operationId,
    );
  }

  Future<void> deleteLine(
    String sessionId,
    String itemCode, {
    required String operationId,
  }) async {
    await _request(
      'DELETE',
      '/api/sessions/$sessionId/items/$itemCode',
      idempotencyKey: operationId,
    );
  }

  Future<Ticket> complete(String sessionId, {required String operationId}) async {
    final data = await _request(
      'POST',
      '/api/sessions/$sessionId/complete',
      body: {'client_operation_id': operationId},
      idempotencyKey: operationId,
    );
    return Ticket.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<HistoryEntry>> history({String? itemCode}) async {
    final p = itemCode == null ? '' : '?item_code=${Uri.encodeQueryComponent(itemCode)}';
    final data = await _request('GET', '/api/sales/history$p');
    return _list(data).map(HistoryEntry.fromJson).toList();
  }

  Future<Map<String, dynamic>> adminUpsert(
    String resource,
    Map<String, dynamic> body, {
    String? id,
    required String operationId,
  }) async {
    final data = await _request(
      id == null ? 'POST' : 'PUT',
      '/api/$resource${id == null ? '' : '/$id'}',
      body: {...body, 'client_operation_id': operationId},
      idempotencyKey: operationId,
    );
    return Map<String, dynamic>.from(data ?? {});
  }

  Future<void> adminDelete(
    String resource,
    String id, {
    required String operationId,
  }) async {
    await _request(
      'DELETE',
      '/api/$resource/$id',
      idempotencyKey: operationId,
    );
  }

  List<Map<String, dynamic>> _list(dynamic data) {
    final raw = data is List
        ? data
        : (data is Map ? (data['items'] ?? data['data'] ?? data['results'] ?? []) : []);
    return (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  AuthSession _sessionFromLogin(dynamic data, String username) {
    final map = Map<String, dynamic>.from(data as Map);
    final user = map['user'] is Map
        ? UserAccount.fromJson(Map<String, dynamic>.from(map['user']))
        : UserAccount.fromJson({
            'username': username,
            'display_name': username,
            'role': map['role'] ?? 'sales',
            'permissions': map['permissions'],
          });
    return AuthSession(
      accessToken: '${map['access_token'] ?? map['token'] ?? ''}',
      refreshToken: map['refresh_token'] == null ? null : '${map['refresh_token']}',
      accessTokenExpiresAt: _expiresAt(map),
      user: user,
    );
  }

  AuthSession _sessionFromRefresh(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    return AuthSession(
      accessToken: '${map['access_token'] ?? map['token'] ?? _session?.accessToken ?? ''}',
      refreshToken: map['refresh_token'] == null ? _session?.refreshToken : '${map['refresh_token']}',
      accessTokenExpiresAt: _expiresAt(map),
      user: map['user'] is Map
          ? UserAccount.fromJson(Map<String, dynamic>.from(map['user']))
          : _session!.user,
    );
  }

  DateTime? _expiresAt(Map<String, dynamic> map) {
    final explicit = map['expires_at'] ?? map['access_token_expires_at'];
    if (explicit != null) return DateTime.tryParse('$explicit');
    final seconds = map['expires_in'];
    if (seconds is num) return DateTime.now().add(Duration(seconds: seconds.toInt()));
    return null;
  }

  String _message(dynamic data) {
    if (data is Map) return '${data['detail'] ?? data['message'] ?? data['error'] ?? data}';
    return '$data';
  }
}
