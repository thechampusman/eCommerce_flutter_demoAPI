import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_user.dart';

class AuthApiService {
  static const String baseUrl = 'https://dummyjson.com';

  static Future<ApiUser> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'expiresInMins': 30,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiUser.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<ApiUser> getCurrentUser(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return ApiUser.fromJson({
          ...data,
          'accessToken': accessToken,
          'refreshToken': '', 
        });
      } else {
        throw Exception('Failed to get current user');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<ApiUser> refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiUser.fromJson(data);
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
