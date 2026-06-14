import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _usersKey = 'fixxi_users';
  static const _sessionKey = 'fixxi_session';
  static const _requestsKey = 'fixxi_requests';
  static const _messagesKey = 'fixxi_messages';
  static const _reviewsKey = 'fixxi_reviews';
  static const _notificationsKey = 'fixxi_notifications';
  static const _themeKey = 'fixxi_theme_dark';
  static const _seedKey = 'fixxi_seeded';
  static const _apiBaseKey = 'fixxi_api_base';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> isSeeded() async {
    final p = await _getPrefs;
    return p.getBool(_seedKey) ?? false;
  }

  Future<void> markSeeded() async {
    final p = await _getPrefs;
    await p.setBool(_seedKey, true);
  }

  Future<bool> isDarkMode() async {
    final p = await _getPrefs;
    return p.getBool(_themeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final p = await _getPrefs;
    await p.setBool(_themeKey, value);
  }

  Future<String?> getApiBaseUrl() async {
    final p = await _getPrefs;
    return p.getString(_apiBaseKey);
  }

  Future<void> setApiBaseUrl(String url) async {
    final p = await _getPrefs;
    await p.setString(_apiBaseKey, url);
  }

  Future<String?> getSessionUserId() async {
    final p = await _getPrefs;
    return p.getString(_sessionKey);
  }

  Future<void> setSessionUserId(String? userId) async {
    final p = await _getPrefs;
    if (userId == null) {
      await p.remove(_sessionKey);
    } else {
      await p.setString(_sessionKey, userId);
    }
  }

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final p = await _getPrefs;
    final raw = p.getString(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> data) async {
    final p = await _getPrefs;
    await p.setString(key, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>> getUsers() => readList(_usersKey);
  Future<void> saveUsers(List<Map<String, dynamic>> users) =>
      writeList(_usersKey, users);

  Future<List<Map<String, dynamic>>> getRequests() => readList(_requestsKey);
  Future<void> saveRequests(List<Map<String, dynamic>> requests) =>
      writeList(_requestsKey, requests);

  Future<List<Map<String, dynamic>>> getMessages() => readList(_messagesKey);
  Future<void> saveMessages(List<Map<String, dynamic>> messages) =>
      writeList(_messagesKey, messages);

  Future<List<Map<String, dynamic>>> getReviews() => readList(_reviewsKey);
  Future<void> saveReviews(List<Map<String, dynamic>> reviews) =>
      writeList(_reviewsKey, reviews);

  Future<List<Map<String, dynamic>>> getNotifications() =>
      readList(_notificationsKey);
  Future<void> saveNotifications(List<Map<String, dynamic>> notifications) =>
      writeList(_notificationsKey, notifications);
}

/// Simple distance estimate between two lat/lng points (km).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _degToRad(double deg) => deg * pi / 180;
