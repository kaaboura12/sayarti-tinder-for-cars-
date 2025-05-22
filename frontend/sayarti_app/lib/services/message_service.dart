import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class MessageService {
  // Use same baseUrl pattern as other services
  final String baseUrl = kIsWeb 
    ? 'http://localhost:5000/api' 
    : 'http://10.0.2.2:5000/api';
  
  // Get all conversations for the current user with pagination
  Future<List<Conversation>> getConversations(String token, {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> conversationsJson = jsonDecode(response.body);
        
        return conversationsJson.map((json) {
          try {
            // Ensure required fields exist or have defaults
            final safeJson = Map<String, dynamic>.from(json);
            
            // Set default values for potentially missing fields
            safeJson['id'] ??= 0;
            safeJson['car_id'] ??= 0;
            safeJson['car_title'] ??= 'Unknown car';
            safeJson['other_user_id'] ??= 0;
            safeJson['other_user_name'] ??= '';
            safeJson['other_user_firstname'] ??= '';
            
            return Conversation.fromJson(safeJson);
          } catch (e) {
            print('Error parsing conversation: $e, data: $json');
            return null;
          }
        }).whereType<Conversation>().toList();
      } else {
        print('Error fetching conversations: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception when fetching conversations: $e');
      return [];
    }
  }
  
  // Get a specific conversation by ID with pagination
  Future<Map<String, dynamic>> getConversationById(int conversationId, String token, {int page = 1, int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations/$conversationId?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final conversationData = data['conversation'];
        final List<dynamic> messagesJson = data['messages'] ?? [];
        
        if (conversationData != null) {
          // Ensure required fields exist or have defaults
          final safeJson = Map<String, dynamic>.from(conversationData);
          
          // Set default values for potentially missing fields
          safeJson['id'] ??= conversationId;
          safeJson['car_id'] ??= 0;
          safeJson['car_title'] ??= 'Unknown car';
          safeJson['other_user_id'] ??= 0;
          safeJson['other_user_name'] ??= '';
          safeJson['other_user_firstname'] ??= '';
          
          try {
            return {
              'conversation': Conversation.fromJson(safeJson),
              'messages': messagesJson.map((json) => Message.fromJson(json)).toList(),
              'pagination': data['pagination'] ?? {'page': page, 'limit': limit},
            };
          } catch (e) {
            print('Error parsing conversation data: $e');
            return {
              'conversation': null,
              'messages': <Message>[],
              'pagination': {'page': page, 'limit': limit},
            };
          }
        } else {
          return {
            'conversation': null,
            'messages': <Message>[],
            'pagination': {'page': page, 'limit': limit},
          };
        }
      } else {
        print('Error fetching conversation: ${response.body}');
        return {
          'conversation': null,
          'messages': <Message>[],
          'pagination': {'page': page, 'limit': limit},
        };
      }
    } catch (e) {
      print('Exception when fetching conversation: $e');
      return {
        'conversation': null,
        'messages': <Message>[],
        'pagination': {'page': page, 'limit': limit},
      };
    }
  }
  
  // Get or create a conversation between users about a specific car
  Future<Map<String, dynamic>> getOrCreateConversation(int otherUserId, int carId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversation/$otherUserId/$carId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final conversationData = data['conversation'];
        final List<dynamic> messagesJson = data['messages'] ?? [];
        
        if (conversationData != null) {
          // Ensure required fields exist or have defaults
          final safeJson = Map<String, dynamic>.from(conversationData);
          
          // Set default values for potentially missing fields
          safeJson['id'] ??= 0;
          safeJson['car_id'] ??= carId;
          safeJson['car_title'] ??= 'Unknown car';
          safeJson['other_user_id'] ??= otherUserId;
          safeJson['other_user_name'] ??= '';
          safeJson['other_user_firstname'] ??= '';
          
          try {
            return {
              'conversation': Conversation.fromJson(safeJson),
              'messages': messagesJson.map((json) => Message.fromJson(json)).toList(),
            };
          } catch (e) {
            print('Error parsing conversation data: $e');
            return {
              'conversation': null,
              'messages': <Message>[],
            };
          }
        } else {
          print('Conversation data is null in the response');
          return {
            'conversation': null,
            'messages': <Message>[],
          };
        }
      } else {
        print('Error getting or creating conversation: ${response.body}');
        return {
          'conversation': null,
          'messages': <Message>[],
        };
      }
    } catch (e) {
      print('Exception when getting or creating conversation: $e');
      return {
        'conversation': null,
        'messages': <Message>[],
      };
    }
  }
  
  // Get messages between current user and another user about a specific car
  Future<List<Message>> getConversation(int otherUserId, int carId, String token) async {
    try {
      final result = await getOrCreateConversation(otherUserId, carId, token);
      final messages = result['messages'];
      
      // Make sure we return an empty list rather than null if there are no messages
      if (messages == null) {
        return [];
      }
      
      return messages as List<Message>;
    } catch (e) {
      print('Exception when fetching conversation: $e');
      return [];
    }
  }
  
  // Send a message using conversation ID (preferred method)
  Future<Message?> sendMessageToConversation({
    required int conversationId, 
    required String message, 
    required String token
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'message': message,
        }),
      );
      
      if (response.statusCode == 201) {
        final messageJson = jsonDecode(response.body);
        return Message.fromJson(messageJson);
      } else {
        print('Error sending message: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception when sending message: $e');
      return null;
    }
  }
  
  // Send a message using user ID and car ID (legacy method, still supported)
  Future<Message?> sendMessage({
    required int receiverId, 
    required int carId, 
    required String message, 
    required String token
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receiver_id': receiverId,
          'car_id': carId,
          'message': message,
        }),
      );
      
      if (response.statusCode == 201) {
        final messageJson = jsonDecode(response.body);
        return Message.fromJson(messageJson);
      } else {
        print('Error sending message: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception when sending message: $e');
      return null;
    }
  }
  
  // Get count of unread messages
  Future<int> getUnreadCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/unread/count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        print('Error getting unread count: ${response.body}');
        return 0;
      }
    } catch (e) {
      print('Exception when getting unread count: $e');
      return 0;
    }
  }
  
  // Delete a conversation
  Future<bool> deleteConversation(int conversationId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/messages/conversations/$conversationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Exception when deleting conversation: $e');
      return false;
    }
  }
} 