import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/socket_provider.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;
  Timer? _authCheckTimer;
  bool _isProcessingAuth = false;

  @override
  void initState() {
    super.initState();
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Logo scale animation
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    // Text opacity animation
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );
    
    // Slide animation for tagline
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Start animation
    _controller.forward();
    
    // Check authentication status after animation starts
    _authCheckTimer = Timer(const Duration(milliseconds: 800), () {
      _checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _authCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    if (_isProcessingAuth) return;
    
    setState(() {
      _isProcessingAuth = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final socketProvider = Provider.of<SocketProvider>(context, listen: false);
      
      // Wait for auth provider to complete initialization if it's still loading
      if (authProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      final isAuthenticated = authProvider.isAuthenticated;
      
      // Complete animation before navigating
      if (!_controller.isCompleted) {
        await _controller.forward().orCancel;
      }
      
      // Restore system UI before navigation
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      
      if (!mounted) return;
      
      // Initialize socket if authenticated
      if (isAuthenticated) {
        final token = await authProvider.token;
        if (token != null) {
          socketProvider.initialize(token);
        }
        
        // Navigate to home screen with fade transition
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        // Navigate to login screen with fade transition
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        
        // Navigate to login on error
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppTheme.textColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Upper spacer that takes 1/3 of available space
          const Spacer(),
          
          // Logo and content taking 2/3 of available space
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo container
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.accentColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(isDarkMode ? 0.3 : 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.directions_car,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Animated "SAYARTI" text
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Text(
                        'SAYARTI',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppTheme.primaryColor,
                          shadows: [
                            Shadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Animated tagline with slide-up effect
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Text(
                          'The Future of Car Trading',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Bottom section with loading indicator
          Expanded(
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 