import 'dart:convert';
import 'package:flutter/material.dart';

class ErrorHandler {
  /// Handles API errors and returns a user-friendly message
  static String handleApiError(dynamic error, String defaultMessage) {
    try {
      // If the error is a string representation of JSON
      if (error is String && error.contains('{') && error.contains('}')) {
        try {
          final Map<String, dynamic> errorData = jsonDecode(error);
          
          // Handle specific error messages
          if (errorData.containsKey('error')) {
            final String errorMsg = errorData['error'];
            
            // Handle disk space errors
            if (errorMsg.contains('No space left on device')) {
              return 'Server storage full. Please try again later or contact support.';
            }
            
            return errorMsg;
          }
          
          if (errorData.containsKey('message')) {
            return errorData['message'];
          }
        } catch (_) {
          // JSON parsing failed, return the original error
          return error.toString();
        }
      }
      
      return error.toString();
    } catch (_) {
      return defaultMessage;
    }
  }
  
  /// Shows a standardized error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
} 