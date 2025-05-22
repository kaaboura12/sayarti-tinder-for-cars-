import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';
import '../models/message_model.dart';

class SocketProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  bool _isInitialized = false;
  int _unreadNotificationCount = 0;

  bool get isConnected => _socketService.isConnected;
  bool get isInitialized => _isInitialized;
  Map<int, bool> get typingUsers => _socketService.typingUsers;
  int get unreadNotificationCount => _unreadNotificationCount;

  // Initialize the socket connection
  void initialize(String token) {
    if (!_isInitialized) {
      _socketService.connect(token);
      _setupListeners();
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  // Setup socket event listeners
  void _setupListeners() {
    // Listen for connection status changes
    _socketService.addListener(() {
      notifyListeners();
    });
    
    // Listen for notification updates
    _socketService.onNotificationUpdate((count) {
      _unreadNotificationCount = count;
      notifyListeners();
    });
  }
  
  // Send a message via socket
  void sendMessage({
    required int receiverId,
    required int carId,
    required int conversationId,
    required String message,
    required String senderName,
  }) {
    _socketService.sendMessage(
      receiverId: receiverId,
      carId: carId,
      conversationId: conversationId,
      message: message,
      senderName: senderName,
    );
  }
  
  // Listen for incoming messages in a specific conversation
  void listenForMessages(Function(Message) onMessageReceived) {
    _socketService.onReceiveMessage(onMessageReceived);
  }
  
  // Send typing status
  void sendTypingStatus({
    required int receiverId,
    required int conversationId,
    required bool isTyping,
  }) {
    _socketService.sendTypingStatus(
      receiverId: receiverId, 
      conversationId: conversationId, 
      isTyping: isTyping
    );
  }
  
  // Listen for typing status updates
  void listenForTypingStatus(Function(int, int, bool) onTypingUpdate) {
    _socketService.onTypingUpdate(onTypingUpdate);
  }
  
  // Reset typing status for a user
  void resetTypingStatus(int userId) {
    _socketService.resetTypingStatus(userId);
  }
  
  // Set unread notification count
  void setUnreadNotificationCount(int count) {
    _unreadNotificationCount = count;
    notifyListeners();
  }
  
  // Clean up resources
  void dispose() {
    if (_isInitialized) {
      _socketService.disconnect();
      _isInitialized = false;
    }
    super.dispose();
  }
} 