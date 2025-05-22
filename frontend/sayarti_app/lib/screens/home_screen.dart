import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/futuristic_navbar.dart';
import '../widgets/notification_icon.dart';
import '../widgets/favorite_icon.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../screens/add_car_screen.dart';
import '../screens/car_swipe_screen.dart';
import '../screens/conversations_screen.dart';
import '../screens/favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home_rounded, label: 'Home'),
    NavItem(icon: Icons.sell, label: 'Sell'),
    NavItem(icon: Icons.shopping_cart_rounded, label: 'Buy'),
    NavItem(icon: Icons.person, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Initialize notifications after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeNotifications());
  }
  
  void _initializeNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    final token = await authProvider.token;
    if (token != null) {
      notificationProvider.initialize(token);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    setState(() => _currentIndex = index);
    
    if (index == 3) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else if (index == 2) {
      // Navigate to Buy (Car Swiper Screen)
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const CarSwipeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else if (index > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_navItems[index].label} feature coming soon!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final user = authProvider.user;
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[100],
      extendBody: true, // Important for the floating navbar effect
      body: authProvider.isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ))
          : SafeArea(
              bottom: false, // Important for the floating navbar effect
              child: Stack(
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDarkMode
                          ? [
                              AppTheme.darkBackgroundColor,
                              AppTheme.darkBackgroundColor,
                              AppTheme.darkSurfaceColor,
                              AppTheme.darkSurfaceColor,
                            ]
                          : [
                              Colors.grey[100]!,
                              Colors.grey[100]!,
                              Colors.grey[100]!,
                              Colors.grey[200]!,
                            ],
                      ),
                    ),
                  ),
                  
                  // Decorative elements
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode
                          ? AppTheme.primaryColor.withOpacity(0.03)
                          : AppTheme.primaryColor.withOpacity(0.05),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    bottom: -80,
                    left: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode
                          ? AppTheme.primaryColor.withOpacity(0.05)
                          : AppTheme.primaryColor.withOpacity(0.07),
                      ),
                    ),
                  ),
                  
                  // Animated floating particles (super futuristic effect)
                  _buildAnimatedParticles(isDarkMode),
                  
                  // App title and logo
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'SAYARTI',
                            style: (isDarkMode ? AppTheme.darkHeadingLarge : AppTheme.headingLarge).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text(
                            'The Future of Car Trading',
                            style: (isDarkMode ? AppTheme.darkBodySmall : AppTheme.bodySmall).copyWith(
                              color: isDarkMode ? AppTheme.darkTextLightColor : AppTheme.textLightColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Notification and Favorites icons
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        // Favorites icon
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: const FavoriteIcon(),
                        ),
                        // Notification icon
                        const NotificationIcon(),
                      ],
                    ),
                  ),
                  
                  // User greeting with 3D floating effect
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                            ? AppTheme.darkSurfaceColor.withOpacity(0.7)
                            : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                              child: Text(
                                _getInitials(user),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user != null ? 'Welcome, ${user.firstname}!' : 'Welcome!',
                              style: (isDarkMode ? AppTheme.darkBodyMedium : AppTheme.bodyMedium).copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Main content with the two main buttons
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.85,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Modern car illustration with particle effects
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glowing ring
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.7, 1.0],
                                  ),
                                ),
                              ),
                              // Main car icon container with 3D effect
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.7),
                                      AppTheme.primaryDarkColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(75),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                              // Pulsating effect
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.8, end: 1.1),
                                duration: const Duration(seconds: 2),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: (2.0 - value).clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: value,
                                      child: Container(
                                        width: 150,
                                        height: 150,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.primaryColor.withOpacity(0.3),
                                            width: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                onEnd: () {
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 50),
                          
                          // Sell button with futuristic animation effects
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 0.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, value * 50),
                                child: Opacity(
                                  opacity: 1 - value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: CustomButton(
                                          text: 'SELL YOUR CAR',
                                          icon: Icons.sell,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const AddCarScreen(),
                                              ),
                                            );
                                          },
                                          backgroundColor: Colors.orange,
                                          height: 60,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Buy button with futuristic animation effects
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 0.0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, value * 50),
                                child: Opacity(
                                  opacity: 1 - value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: CustomButton(
                                          text: 'BUY A CAR',
                                          icon: Icons.shopping_cart,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const CarSwipeScreen(),
                                              ),
                                            );
                                          },
                                          backgroundColor: Colors.green,
                                          height: 60,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Messages button with animation effects
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 0.0),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, value * 50),
                                child: Opacity(
                                  opacity: 1 - value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: CustomButton(
                                          text: 'MY MESSAGES',
                                          icon: Icons.message_rounded,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const ConversationsScreen(),
                                              ),
                                            );
                                          },
                                          backgroundColor: Colors.blue,
                                          height: 60,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      
      // Ultra-futuristic floating navigation bar
      bottomNavigationBar: FuturisticNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _handleNavigation,
        items: _navItems,
      ),
    );
  }
  
  // Generate animated floating particles for a futuristic effect
  Widget _buildAnimatedParticles(bool isDarkMode) {
    return Stack(
      children: List.generate(10, (index) {
        final random = DateTime.now().millisecondsSinceEpoch + index * 500;
        final top = (random % 700).toDouble();
        final left = (random % 400).toDouble();
        final size = (random % 8 + 3).toDouble();
        final opacity = (random % 7 + 3) / 10;
        
        return Positioned(
          top: top,
          left: left,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(seconds: (random % 5 + 5)),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: (opacity * (1 - (value * 0.5))).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(
                    math.sin(value * 3 * math.pi) * 10,
                    math.cos(value * 2 * math.pi) * 10,
                  ),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(isDarkMode ? 0.3 : 0.5),
                          blurRadius: isDarkMode ? 3 : 5,
                          spreadRadius: isDarkMode ? 0 : 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted) {
                setState(() {});
              }
            },
          ),
        );
      }),
    );
  }

  String _getInitials(User? user) {
    if (user == null || (user.firstname.isEmpty && user.name.isEmpty)) {
      return 'U';
    }
    
    final firstInitial = user.firstname.isNotEmpty ? user.firstname[0] : '';
    final lastInitial = user.name.isNotEmpty ? user.name[0] : '';
    
    return (firstInitial + lastInitial).toUpperCase();
  }
}

// Custom painter that draws a grid pattern for decoration
class GridPatternPainter extends CustomPainter {
  final bool isDarkMode;
  
  GridPatternPainter({this.isDarkMode = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.white).withOpacity(isDarkMode ? 0.2 : 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal lines
    double spacing = 20;
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    // Draw some dots at intersections for more texture
    final dotPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.white).withOpacity(isDarkMode ? 0.3 : 0.5)
      ..style = PaintingStyle.fill;
      
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if ((x ~/ spacing + y ~/ spacing) % 3 == 0) { // Create a pattern by skipping some dots
          canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 