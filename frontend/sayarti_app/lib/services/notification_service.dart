import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/notification_model.dart' as notification_model;

class NotificationService {
  final String baseUrl = kIsWeb 
    ? 'http://localhost:5000/api' 
    : 'http://10.0.2.2:5000/api';
  
  // Get all notifications for current user
  Future<List<notification_model.Notification>> getNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> notificationsJson = jsonDecode(response.body);
        return notificationsJson.map((json) => notification_model.Notification.fromJson(json)).toList();
      } else {
        print('Error fetching notifications: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception when fetching notifications: $e');
      return [];
    }
  }
  
  // Get unread notifications count
  Future<int> getUnreadCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread/count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        print('Error getting unread notification count: ${response.body}');
        return 0;
      }
    } catch (e) {
      print('Exception when getting unread notification count: $e');
      return 0;
    }
  }
  
  // Mark a notification as read
  Future<bool> markAsRead(int notificationId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Exception when marking notification as read: $e');
      return false;
    }
  }
  
  // Mark all notifications as read
  Future<bool> markAllAsRead(String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Exception when marking all notifications as read: $e');
      return false;
    }
  }
} 