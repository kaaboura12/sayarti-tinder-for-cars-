import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart' as notification_model;
import '../services/notification_service.dart';
import '../services/message_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final MessageService _messageService = MessageService();
  
  List<notification_model.Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  
  List<notification_model.Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  
  Timer? _refreshTimer;
  
  // Initialize notifications and set up periodic refresh
  void initialize(String token) {
    fetchNotifications(token);
    
    // Refresh notifications every minute
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchNotifications(token);
    });
  }
  
  // Clean up resources
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  // Fetch notifications from the API
  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get notifications from the API
      final notifications = await _notificationService.getNotifications(token);
      _notifications = notifications;
      
      // Get unread count from API
      _unreadCount = await _notificationService.getUnreadCount(token);
      
      // Also check for unread messages and include them in the count
      final unreadMessages = await _messageService.getUnreadCount(token);
      _unreadCount += unreadMessages;
    } catch (e) {
      print('Error in fetchNotifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Mark a notification as read
  Future<void> markAsRead(int notificationId, String token) async {
    try {
      // Convert notificationId to ensure it's an integer
      final id = notificationId is int ? notificationId : int.tryParse(notificationId.toString()) ?? 0;
      if (id <= 0) {
        print('Invalid notification ID: $notificationId');
        return;
      }
      
      final success = await _notificationService.markAsRead(id, token);
      if (success) {
        // Update local state
        _notifications = _notifications.map((notification) {
          if (notification.id == id && !notification.isRead) {
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
            return notification_model.Notification(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              targetId: notification.targetId,
              isRead: true,
              createdAt: notification.createdAt,
            );
          }
          return notification;
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error in markAsRead: $e');
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead(String token) async {
    try {
      final success = await _notificationService.markAllAsRead(token);
      if (success) {
        // Update local state
        _notifications = _notifications.map((notification) => 
          notification_model.Notification(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            targetId: notification.targetId,
            isRead: true,
            createdAt: notification.createdAt,
          )
        ).toList();
        
        // Get unread messages count (since message notifications are separate)
        final unreadMessages = await _messageService.getUnreadCount(token);
        _unreadCount = unreadMessages;
        
        notifyListeners();
      }
    } catch (e) {
      print('Error in markAllAsRead: $e');
    }
  }
} 