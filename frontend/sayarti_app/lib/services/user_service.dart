import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';

class UserService {
  // Use same baseUrl pattern as other services
  final String baseUrl = kIsWeb 
    ? 'http://localhost:5000/api' 
    : 'http://10.0.2.2:5000/api';
  
  // Get user details by ID
  Future<User?> getUserById(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return User.fromJson(userData);
      } else {
        print('Error fetching user details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception when fetching user details: $e');
      return null;
    }
  }
} 