import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class LocalStore {
  static const _legacyStateKey = 'sales_price_assistant_state_v1';
  static const _apiBaseUrlKey = 'api_base_url';
  static const _sessionKey = 'sales_price_assistant_auth_session_v1';

  SharedPreferences? _prefs;
  File? _stateFile;

  LocalStore();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    _stateFile = File('${dir.path}${Platform.pathSeparator}sales_price_assistant_state_v2.json');
    await _migrateLegacyState();
  }

  Map<String, dynamic>? read() {
    final file = _stateFile;
    if (file == null || !file.existsSync()) return null;
    final content = file.readAsStringSync();
    if (content.trim().isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(content));
  }

  Future<void> write(Map<String, dynamic> state) async {
    final file = _stateFile;
    if (file == null) return;
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(state), flush: true);
    if (await file.exists()) await file.delete();
    await tmp.rename(file.path);
  }

  Future<void> clear() async {
    final file = _stateFile;
    if (file != null && await file.exists()) await file.delete();
    await _prefs?.remove(_legacyStateKey);
    await clearAuthSession();
  }

  String? get apiBaseUrl => _prefs?.getString(_apiBaseUrlKey);

  Future<void> setApiBaseUrl(String value) async {
    await _prefs?.setString(_apiBaseUrlKey, value);
  }

  Future<AuthSession?> readAuthSession() async {
    final raw = _prefs?.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    return AuthSession.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  Future<void> writeAuthSession(AuthSession session) async {
    await _prefs?.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearAuthSession() async {
    await _prefs?.remove(_sessionKey);
  }

  Future<void> _migrateLegacyState() async {
    final file = _stateFile;
    if (file == null || await file.exists()) return;
    final legacy = _prefs?.getString(_legacyStateKey);
    if (legacy == null || legacy.trim().isEmpty) return;
    await write(Map<String, dynamic>.from(jsonDecode(legacy)));
    await _prefs?.remove(_legacyStateKey);
  }
}
