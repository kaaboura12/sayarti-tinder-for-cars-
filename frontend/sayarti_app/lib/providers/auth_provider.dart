import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  
  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  
  // Token getter
  Future<String?> get token async => await _authService.getToken();
  
  // Constructor - initialize auth state
  AuthProvider() {
    _checkAuthStatus();
  }
  
  // Check if user is authenticated
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    _isAuthenticated = await _authService.isAuthenticated();
    
    if (_isAuthenticated) {
      _user = await _authService.getCurrentUser();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Register a new user
  Future<bool> register({
    required String name,
    required String firstname,
    required String email,
    required String numerotlf,
    required String motdepasse,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.register(
        name: name,
        firstname: firstname,
        email: email,
        numerotlf: numerotlf,
        motdepasse: motdepasse,
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = "An unexpected error occurred: $e";
      notifyListeners();
      return false;
    }
  }
  
  // Login user
  Future<bool> login({
    required String email,
    required String motdepasse,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.login(
        email: email,
        motdepasse: motdepasse,
      );
      
      if (response['success'] == true) {
        _isAuthenticated = true;
        _user = await _authService.getCurrentUser();
        
        // Double check we actually got a user
        if (_user == null) {
          _errorMessage = "Failed to load user data";
          _isAuthenticated = false;
        }
      } else {
        _errorMessage = response['message'];
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = "An unexpected error occurred: $e";
      _isAuthenticated = false;
    }
    
    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }
  
  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.logout();
    
    _isAuthenticated = false;
    _user = null;
    
    _isLoading = false;
    notifyListeners();
  }
} 