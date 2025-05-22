import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/car_model.dart';
import '../utils/error_handler.dart';

class FavoriteService {
  final String baseUrl = kIsWeb 
    ? 'http://localhost:5000/api' 
    : 'http://10.0.2.2:5000/api';
  
  // Get all favorite cars for the current user
  Future<List<Car>> getFavorites(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> favoritesJson = jsonDecode(response.body);
        return favoritesJson.map((json) => Car.fromJson(json)).toList();
      } else {
        final errorMessage = ErrorHandler.handleApiError(
          response.body, 
          'Error fetching favorites'
        );
        print('Error fetching favorites: $errorMessage');
        return [];
      }
    } catch (e) {
      print('Exception when fetching favorites: $e');
      return [];
    }
  }
  
  // Add a car to favorites
  Future<bool> addToFavorites(int carId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/$carId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      final errorMessage = ErrorHandler.handleApiError(
        e.toString(), 
        'Exception when adding to favorites'
      );
      print(errorMessage);
      return false;
    }
  }
  
  // Remove a car from favorites
  Future<bool> removeFromFavorites(int carId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/$carId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      final errorMessage = ErrorHandler.handleApiError(
        e.toString(), 
        'Exception when removing from favorites'
      );
      print(errorMessage);
      return false;
    }
  }
  
  // Check if a car is favorited
  Future<bool> isFavorited(int carId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites/check/$carId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorited'] ?? false;
      } else {
        final errorMessage = ErrorHandler.handleApiError(
          response.body, 
          'Error checking favorite status'
        );
        print(errorMessage);
        return false;
      }
    } catch (e) {
      print('Exception when checking favorite status: $e');
      return false;
    }
  }
} 