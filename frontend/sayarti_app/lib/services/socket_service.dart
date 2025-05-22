import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message_model.dart';

class SocketService with ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;
  Map<int, bool> _typingUsers = {};

  bool get isConnected => _isConnected;
  Map<int, bool> get typingUsers => _typingUsers;

  // Connect to socket server with authentication token
  void connect(String token) {
    String baseUrl = kIsWeb 
      ? 'http://localhost:5000' 
      : 'http://10.0.2.2:5000';
      
    try {
      _socket = IO.io(baseUrl, 
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build()
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        print('Socket connected');
        _isConnected = true;
        notifyListeners();
      });

      _socket?.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
        notifyListeners();
      });

      _socket?.onConnectError((error) {
        print('Socket connection error: $error');
        _isConnected = false;
        notifyListeners();
      });

      _socket?.onError((error) {
        print('Socket error: $error');
      });
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  // Send a message
  void sendMessage({
    required int receiverId,
    required int carId,
    required int conversationId,
    required String message,
    required String senderName,
  }) {
    if (_socket != null && _isConnected) {
      final messageData = {
        'receiver_id': receiverId,
        'car_id': carId,
        'conversationId': conversationId,
        'message': message,
        'senderName': senderName,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      _socket?.emit('send_message', messageData);
    }
  }

  // Listen for incoming messages
  void onReceiveMessage(Function(Message) callback) {
    _socket?.on('receive_message', (data) {
      try {
        final message = Message(
          id: data['messageId'] ?? 0,
          senderId: data['senderId'],
          receiverId: 0, // Will be set correctly in the UI
          carId: data['carId'],
          message: data['message'],
          createdAt: data['createdAt'] ?? DateTime.now().toIso8601String(),
          isRead: false,
          senderFirstname: data['senderName']?.split(' ')[0],
          senderName: data['senderName']?.split(' ').length > 1 
            ? data['senderName'].split(' ')[1] 
            : '',
        );
        
        callback(message);
      } catch (e) {
        print('Error parsing received message: $e');
      }
    });
  }

  // Listen for notification updates
  void onNotificationUpdate(Function(int) callback) {
    _socket?.on('notification_update', (data) {
      try {
        final count = data['count'] as int;
        callback(count);
      } catch (e) {
        print('Error handling notification update: $e');
      }
    });
  }

  // Send typing indicator
  void sendTypingStatus({
    required int receiverId,
    required int conversationId,
    required bool isTyping,
  }) {
    if (_socket != null && _isConnected) {
      _socket?.emit('typing', {
        'receiver_id': receiverId,
        'conversationId': conversationId,
        'isTyping': isTyping,
      });
    }
  }

  // Listen for typing indicators
  void onTypingUpdate(Function(int, int, bool) callback) {
    _socket?.on('typing', (data) {
      try {
        final senderId = data['senderId'] as int;
        final conversationId = data['conversationId'] as int;
        final isTyping = data['isTyping'] as bool;
        
        _typingUsers[senderId] = isTyping;
        notifyListeners();
        
        callback(senderId, conversationId, isTyping);
      } catch (e) {
        print('Error handling typing update: $e');
      }
    });
  }

  // Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _typingUsers.clear();
    notifyListeners();
  }

  // Reset typing status
  void resetTypingStatus(int userId) {
    if (_typingUsers.containsKey(userId)) {
      _typingUsers[userId] = false;
      notifyListeners();
    }
  }
} 