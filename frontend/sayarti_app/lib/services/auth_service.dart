import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  // For web use localhost, for Android emulator use 10.0.2.2, for iOS simulator use 127.0.0.1
  final String baseUrl = kIsWeb 
    ? 'http://localhost:5000/api' 
    : 'http://10.0.2.2:5000/api';
  
  // Use secure storage for mobile, shared preferences for web
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  
  // Store token using the appropriate method based on platform
  Future<void> _saveToken(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await secureStorage.write(key: key, value: value);
    }
  }
  
  // Retrieve token using the appropriate method based on platform
  Future<String?> _getToken(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await secureStorage.read(key: key);
    }
  }
  
  // Delete token using the appropriate method based on platform
  Future<void> _deleteToken(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await secureStorage.delete(key: key);
    }
  }
  
  // Register a new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String firstname,
    required String email,
    required String numerotlf,
    required String motdepasse,
  }) async {
    try {
      final payload = jsonEncode({
        'name': name,
        'firstname': firstname,
        'email': email,
        'numerotlf': numerotlf,
        'motdepasse': motdepasse,
      });
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: payload,
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server returned status code ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String motdepasse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'motdepasse': motdepasse,
        }),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Save token and user data
          await _saveToken('token', data['token']);
          await _saveToken('user', jsonEncode(data['user']));
        }
        
        return data;
      } else {
        return {
          'success': false,
          'message': 'Server returned status code ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getToken('token');
    return token != null;
  }
  
  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final userData = await _getToken('user');
      if (userData != null && userData.isNotEmpty) {
        final userMap = jsonDecode(userData);
        if (userMap is Map<String, dynamic>) {
          return User.fromJson(userMap);
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  // Logout
  Future<void> logout() async {
    await _deleteToken('token');
    await _deleteToken('user');
  }
  
  // Get token
  Future<String?> getToken() async {
    return await _getToken('token');
  }
} 