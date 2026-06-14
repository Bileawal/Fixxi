import 'package:flutter/material.dart';

import '../core/constants/api_config.dart';
import '../core/navigation/app_navigator.dart';
import '../models/app_user.dart';
import '../models/technician_profile.dart';
import '../models/user_role.dart';
import '../services/api_client.dart';
import '../services/fixxi_api.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._api, this._client, this._storage);

  final FixxiApi _api;
  final ApiClient _client;
  final StorageService _storage;

  AppUser? _currentUser;
  TechnicianProfile? _technicianProfile;
  bool _isDark = false;
  bool _initialized = false;
  bool _serverOnline = false;
  String? _serverUrl;

  AppUser? get currentUser => _currentUser;
  TechnicianProfile? get technicianProfile => _technicianProfile;
  bool get isDark => _isDark;
  bool get isInitialized => _initialized;
  bool get isLoggedIn => _currentUser != null;
  bool get isCustomer => _currentUser?.role == UserRole.customer;
  bool get isTechnician => _currentUser?.role == UserRole.technician;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get serverOnline => _serverOnline;
  String? get serverUrl => _serverUrl;
  FixxiApi get api => _api;

  Future<void> initialize() async {
    _isDark = await _storage.isDarkMode();
    final saved = await _storage.getApiBaseUrl();
    final discovered = await ApiConfig.discoverServer(savedUrl: saved);
    if (discovered != null) {
      _client.applyBaseUrl(discovered);
      await _storage.setApiBaseUrl(discovered);
      _serverOnline = true;
      _serverUrl = discovered;
    } else {
      _serverOnline = false;
      _serverUrl = null;
    }

    final token = await _client.getToken();
    if (token != null && _serverOnline) {
      try {
        final result = await _api.getMe();
        _currentUser = result.user;
        _technicianProfile = result.technicianProfile;
      } catch (_) {
        await _api.logout();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> retryServerConnection() async {
    final discovered = await ApiConfig.discoverServer(
      savedUrl: await _storage.getApiBaseUrl(),
    );
    if (discovered != null) {
      _client.applyBaseUrl(discovered);
      await _storage.setApiBaseUrl(discovered);
      _serverOnline = true;
      _serverUrl = discovered;
      notifyListeners();
      return true;
    }
    _serverOnline = false;
    notifyListeners();
    return false;
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _storage.setDarkMode(_isDark);
    notifyListeners();
  }

  void setSession(LoginResult result) {
    _currentUser = result.user;
    _technicianProfile = result.technicianProfile;
    notifyListeners();
  }

  void updateTechnicianProfile(TechnicianProfile profile) {
    _technicianProfile = profile;
    notifyListeners();
  }

  void updateUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    _currentUser = null;
    _technicianProfile = null;
    popToRoot();
    notifyListeners();
  }

  void refresh() => notifyListeners();
}
