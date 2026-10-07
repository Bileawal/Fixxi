import 'package:flutter/material.dart';

import '../core/navigation/app_navigator.dart';
import '../models/app_user.dart';
import '../models/technician_profile.dart';
import '../models/user_role.dart';
import '../services/fixxi_api.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._api, this._storage) {
    _pushService = PushNotificationService(_api);
    _locationService = LocationService();
  }

  final FixxiApi _api;
  final StorageService _storage;
  late final PushNotificationService _pushService;
  late final LocationService _locationService;

  AppUser? _currentUser;
  TechnicianProfile? _technicianProfile;
  bool _isDark = false;
  bool _initialized = false;

  AppUser? get currentUser => _currentUser;
  TechnicianProfile? get technicianProfile => _technicianProfile;
  bool get isDark => _isDark;
  bool get isInitialized => _initialized;
  bool get isLoggedIn => _currentUser != null;
  bool get isCustomer => _currentUser?.role == UserRole.customer;
  bool get isTechnician => _currentUser?.role == UserRole.technician;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  FixxiApi get api => _api;

  Future<void> initialize() async {
    _isDark = await _storage.isDarkMode();

    try {
      final result = await _api.getMe();
      _currentUser = result.user;
      _technicianProfile = result.technicianProfile;
      _pushService.initialize();
      _locationService.startTracking();
    } catch (_) {
      _currentUser = null;
      _technicianProfile = null;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _storage.setDarkMode(_isDark);
    notifyListeners();
  }

  void setSession(LoginResult result) {
    _currentUser = result.user;
    _technicianProfile = result.technicianProfile;
    _pushService.initialize();
    _locationService.startTracking();
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
    await _pushService.clearToken();
    _locationService.stopTracking();
    await _api.logout();
    _currentUser = null;
    _technicianProfile = null;
    popToRoot();
    notifyListeners();
  }

  void refresh() => notifyListeners();
}
