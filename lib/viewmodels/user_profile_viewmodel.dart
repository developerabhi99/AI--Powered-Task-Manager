import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfileModel _profile = const UserProfileModel();
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;

  UserProfileViewModel() {
    _loadFromPrefs();
  }

  UserProfileModel get profile => _profile;
  bool get isDarkMode => _isDarkMode;
  bool get isNotificationsEnabled => _isNotificationsEnabled;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _profile = UserProfileModel.fromMap({
      'name': prefs.getString('profile_name'),
      'email': prefs.getString('profile_email'),
      'phone': prefs.getString('profile_phone'),
      'bio': prefs.getString('profile_bio'),
      'avatarPath': prefs.getString('profile_avatarPath'),
    });
    _isNotificationsEnabled = prefs.getBool('is_notifications_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool val) async {
    _isDarkMode = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
  }

  Future<void> setNotificationsEnabled(bool val) async {
    _isNotificationsEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_notifications_enabled', val);
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String bio,
  }) async {
    _profile = _profile.copyWith(name: name, email: email, phone: phone, bio: bio);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_email', email);
    await prefs.setString('profile_phone', phone);
    await prefs.setString('profile_bio', bio);
  }

  Future<void> updateAvatar(String path) async {
    _profile = _profile.copyWith(avatarPath: path);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_avatarPath', path);
  }
}
