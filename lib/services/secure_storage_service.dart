import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_user.dart';

class SecureStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isSkippedKey = 'is_skipped';

  
  static Future<void> storeUserSession(ApiUser user) async {
    await _secureStorage.write(key: _accessTokenKey, value: user.accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: user.refreshToken);

    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, json.encode(user.toJson()));
    await prefs.setBool(_isSkippedKey, false);
  }

  
  static Future<ApiUser?> getUserSession() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userDataKey);

      if (accessToken != null && userData != null) {
        final userJson = json.decode(userData);
        return ApiUser.fromJson({
          ...userJson,
          'accessToken': accessToken,
          'refreshToken': refreshToken ?? '',
        });
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  
  static Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  
  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  
  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  
  static Future<bool> isUserSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSkippedKey) ?? false;
  }

  
  static Future<void> setUserSkipped(bool skipped) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSkippedKey, skipped);
  }

  
  static Future<void> clearUserSession() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_isSkippedKey);
  }

  
  static Future<bool> isLoggedIn() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    return accessToken != null && accessToken.isNotEmpty;
  }
}
