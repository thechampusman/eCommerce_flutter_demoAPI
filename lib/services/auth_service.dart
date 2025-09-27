import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/auth_state.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  AuthStateData _authState = const AuthStateData(state: AuthState.initial);
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  AuthStateData get authState => _authState;
  bool get isAuthenticated => _authState.state == AuthState.authenticated;
  User? get currentUser => _authState.user;

  void _updateState(AuthStateData newState) {
    _authState = newState;
    notifyListeners();
  }

  
  Future<void> initialize() async {
    try {
      final userData = await _storageService.getUser();
      if (userData != null) {
        final user = User.fromJson(jsonDecode(userData));
        _updateState(AuthStateData(state: AuthState.authenticated, user: user));
      } else {
        _updateState(const AuthStateData(state: AuthState.unauthenticated));
      }
    } catch (e) {
      _updateState(const AuthStateData(state: AuthState.unauthenticated));
    }
  }

  
  Future<void> login(String email, String password) async {
    _updateState(const AuthStateData(state: AuthState.loading));

    try {
      final response = await _apiService.login(email, password);

      if (response['success'] == true) {
        final user = User.fromJson(response['user']);
        await _storageService.saveUser(jsonEncode(user.toJson()));

        _updateState(AuthStateData(state: AuthState.authenticated, user: user));
      } else {
        _updateState(
          AuthStateData(
            state: AuthState.error,
            errorMessage: response['message'] ?? 'Login failed',
          ),
        );
      }
    } catch (e) {
      _updateState(
        AuthStateData(
          state: AuthState.error,
          errorMessage: 'Network error occurred',
        ),
      );
    }
  }

  
  Future<void> register(String name, String email, String password) async {
    _updateState(const AuthStateData(state: AuthState.loading));

    try {
      final response = await _apiService.register(name, email, password);

      if (response['success'] == true) {
        final user = User.fromJson(response['user']);
        await _storageService.saveUser(jsonEncode(user.toJson()));

        _updateState(AuthStateData(state: AuthState.authenticated, user: user));
      } else {
        _updateState(
          AuthStateData(
            state: AuthState.error,
            errorMessage: response['message'] ?? 'Registration failed',
          ),
        );
      }
    } catch (e) {
      _updateState(
        AuthStateData(
          state: AuthState.error,
          errorMessage: 'Network error occurred',
        ),
      );
    }
  }

  
  Future<void> logout() async {
    _updateState(const AuthStateData(state: AuthState.loading));

    try {
      await _apiService.logout();
      await _storageService.clearUser();

      _updateState(const AuthStateData(state: AuthState.unauthenticated));
    } catch (e) {
      _updateState(
        AuthStateData(state: AuthState.error, errorMessage: 'Logout failed'),
      );
    }
  }

  
  void clearError() {
    if (_authState.state == AuthState.error) {
      _updateState(
        AuthStateData(state: AuthState.unauthenticated, user: _authState.user),
      );
    }
  }
}
