import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static String get _base {
    if (kIsWeb) return 'http://localhost:5000/api';
    return 'http://172.20.10.9:5000/api'; // ← update with your PC IP
  }

  // ── Token & Session ────────────────────────────────────────────────────
  static Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  static Future<void> setToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token);
  }

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('token');
    return t != null && t.isNotEmpty;
  }

  // setAdmin accepts optional bool so both
  //   Api.setAdmin()       (new style)
  //   Api.setAdmin(true)   (old style)
  // both compile fine
  static Future<void> setAdmin([bool val = true]) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('is_admin', val);
  }

  static Future<bool> isAdmin() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('is_admin') ?? false;
  }

  // ── Profile ────────────────────────────────────────────────────────────
  static Future<void> setProfileComplete() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('profile_complete', true);
  }

  static Future<bool> hasProfile() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('profile_complete') ?? false;
  }

  // Legacy alias
  static Future<bool> profileComplete() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('profile_complete') ?? false;
  }

  // ── PIN ────────────────────────────────────────────────────────────────
  // Both   Api.setHasPin()        and   Api.setHasPin(true/false)   work
  static Future<void> setHasPin([bool val = true]) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('has_pin', val);
  }

  static Future<bool> hasPin() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('has_pin') ?? false;
  }

  // Both   Api.setPinPassed()     and   Api.setPinPassed(true/false) work
  static Future<void> setPinPassed([bool val = true]) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('pin_passed', val);
  }

  static Future<bool> pinPassed() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('pin_passed') ?? false;
  }

  // ── FCM token ──────────────────────────────────────────────────────────
  static Future<String?> getFcmToken() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString('fcm_token');
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveFcmToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('fcm_token', token);
  }

  // ── Clear session ──────────────────────────────────────────────────────
  static Future<void> clearSession() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final t = await _token();
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  static Map<String, dynamic> _parse(http.Response r) {
    try {
      final b = jsonDecode(r.body);
      if (r.statusCode >= 200 && r.statusCode < 300) return b;
      return {
        'error': (b is Map && b['error'] != null)
            ? b['error'].toString()
            : 'Request failed (${r.statusCode})',
      };
    } catch (_) {
      return {'error': 'Server returned invalid data'};
    }
  }

  // ── GET ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final r = await http
          .get(Uri.parse('$_base$path'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      return _parse(r);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  // ── POST ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    try {
      final r = await http
          .post(Uri.parse('$_base$path'),
              headers: await _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _parse(r);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  // ── PUT ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    try {
      final r = await http
          .put(Uri.parse('$_base$path'),
              headers: await _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _parse(r);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final r = await http
          .delete(Uri.parse('$_base$path'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      return _parse(r);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }
}