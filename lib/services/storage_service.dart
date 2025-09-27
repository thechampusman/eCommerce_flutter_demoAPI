import 'package:flutter/foundation.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  
  static final Map<String, String> _storage = {};

  
  Future<void> saveUser(String userData) async {
    _storage[_userKey] = userData;
    debugPrint('User data saved to storage');
  }

  
  Future<String?> getUser() async {
    return _storage[_userKey];
  }

  
  Future<void> saveToken(String token) async {
    _storage[_tokenKey] = token;
  }

  
  Future<String?> getToken() async {
    return _storage[_tokenKey];
  }

  
  Future<void> clearUser() async {
    _storage.remove(_userKey);
    _storage.remove(_tokenKey);
    debugPrint('User data cleared from storage');
  }

  
  Future<bool> hasUserData() async {
    return _storage.containsKey(_userKey);
  }
}
