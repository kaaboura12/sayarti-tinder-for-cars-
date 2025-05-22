import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/futuristic_navbar.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3; // Set profile as the active tab
  
  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home_rounded, label: 'Home'),
    NavItem(icon: Icons.sell, label: 'Sell'),
    NavItem(icon: Icons.shopping_cart_rounded, label: 'Buy'),
    NavItem(icon: Icons.person, label: 'Profile'),
  ];
  
  void _handleNavigation(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    
      if (index == 0) {
        // Navigate back to home
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else if (index != 3) {
        // Show snackbar for other tabs (except profile which we're on)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_navItems[index].label} feature coming soon!')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[100],
      extendBody: true, // Important for the floating navbar
      body: CustomScrollView(
        slivers: [
          // App Bar with user avatar and background
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor: themeProvider.isDarkMode 
              ? AppTheme.darkSurfaceColor
              : AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: themeProvider.isDarkMode 
                          ? [
                              AppTheme.darkSurfaceColor,
                              Colors.black,
                            ]
                          : [
                              AppTheme.primaryColor,
                              AppTheme.primaryDarkColor,
                            ],
                      ),
                    ),
                  ),
                  // Decorative pattern - replacing network image with pattern decoration
                  Opacity(
                    opacity: 0.1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.white.withOpacity(0.3)],
                        ),
                      ),
                      child: CustomPaint(
                        painter: GridPatternPainter(isDarkMode: themeProvider.isDarkMode),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                  
                  // Animated particles for futuristic effect
                  _buildAnimatedParticles(),
                ],
              ),
              title: const Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile coming soon!')),
                  );
                },
              ),
            ],
          ),
          
          // User avatar that overlaps the app bar
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Avatar with initials or image
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        child: Text(
                          _getInitials(user),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    // Camera icon for changing avatar with pulsating effect
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.95, end: 1.05),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentColor.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
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
              ),
            ),
          ),
          
          // User name
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  user != null 
                      ? '${user.firstname} ${user.name}'
                      : 'User Name',
                  style: AppTheme.headingLarge,
                ),
              ),
            ),
          ),
          
          // Member since info
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Member since June 2023',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // User information sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information section
                  _buildSectionTitle('Personal Information'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode 
                              ? AppTheme.darkSurfaceColor.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeProvider.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.person_outline, 
                                'First Name', 
                                user?.firstname ?? 'Not provided'
                              ),
                              const Divider(),
                              _buildInfoRow(
                                Icons.person_outline, 
                                'Last Name', 
                                user?.name ?? 'Not provided'
                              ),
                              const Divider(),
                              _buildInfoRow(
                                Icons.email_outlined, 
                                'Email', 
                                user?.email ?? 'Not provided'
                              ),
                              const Divider(),
                              _buildInfoRow(
                                Icons.phone_outlined, 
                                'Phone', 
                                user?.numerotlf ?? 'Not provided'
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Account Statistics section
                  _buildSectionTitle('Account Statistics'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode 
                              ? AppTheme.darkSurfaceColor.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeProvider.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildStatsRow(
                                Icons.directions_car_outlined,
                                'Cars Listed',
                                '0',
                              ),
                              const Divider(),
                              _buildStatsRow(
                                Icons.shopping_cart_outlined,
                                'Cars Purchased',
                                '0',
                              ),
                              const Divider(),
                              _buildStatsRow(
                                Icons.favorite_outline,
                                'Favorites',
                                '0',
                              ),
                              const Divider(),
                              _buildStatsRow(
                                Icons.star_outline,
                                'Reviews',
                                '0',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Preferences section
                  _buildSectionTitle('Preferences & Settings'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode 
                              ? AppTheme.darkSurfaceColor.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeProvider.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildSettingRow(
                                'Notifications',
                                Icons.notifications_outlined,
                                true,
                                (value) {
                                  // Handle toggle
                                },
                              ),
                              const Divider(height: 1),
                              _buildSettingRow(
                                'Dark Mode',
                                Icons.dark_mode_outlined,
                                Provider.of<ThemeProvider>(context).isDarkMode,
                                (value) {
                                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                                },
                              ),
                              const Divider(height: 1),
                              InkWell(
                                onTap: () {
                                  // Handle tap
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        color: AppTheme.textLightColor,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'Change Password',
                                          style: AppTheme.bodyMedium,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppTheme.textLightColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              InkWell(
                                onTap: () {
                                  // Handle tap
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.language_outlined,
                                        color: AppTheme.textLightColor,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'Language',
                                          style: AppTheme.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        'English',
                                        style: AppTheme.bodySmall,
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppTheme.textLightColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Logout button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 120.0), // Extra padding for bottom nav bar
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade700.withOpacity(0.3),
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
                            text: 'LOGOUT',
                            onPressed: () async {
                              await authProvider.logout();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            isLoading: false,
                            icon: Icons.logout,
                            backgroundColor: Colors.red.shade700,
                            height: 60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  Widget _buildAnimatedParticles() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Stack(
      children: List.generate(8, (index) {
        final random = DateTime.now().millisecondsSinceEpoch + index * 500;
        final top = (random % 250).toDouble();
        final left = (random % 400).toDouble();
        final size = (random % 5 + 2).toDouble();
        final opacity = (random % 6 + 2) / 10;
        
        return Positioned(
          top: top,
          left: left,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(seconds: (random % 4 + 4)),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: (opacity * (1.0 - (value * 0.5))).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(
                    math.sin(value * 3 * math.pi) * 10,
                    math.cos(value * 2 * math.pi) * 10,
                  ),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(isDarkMode ? 0.5 : 0.8),
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
  
  Widget _buildSectionTitle(String title) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: (isDarkMode ? AppTheme.darkHeadingMedium : AppTheme.headingMedium).copyWith(
          fontSize: 18,
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isDarkMode ? AppTheme.darkTextLightColor : AppTheme.textLightColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: (isDarkMode ? AppTheme.darkBodyMedium : AppTheme.bodyMedium).copyWith(
                color: isDarkMode ? AppTheme.darkTextLightColor : AppTheme.textLightColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: isDarkMode ? AppTheme.darkBodyMedium : AppTheme.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsRow(IconData icon, String label, String value) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: isDarkMode ? AppTheme.darkBodyMedium : AppTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: (isDarkMode ? AppTheme.darkBodyMedium : AppTheme.bodyMedium).copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingRow(
    String title,
    IconData icon,
    bool initialValue,
    Function(bool) onChanged,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode ? AppTheme.darkTextLightColor : AppTheme.textLightColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: isDarkMode ? AppTheme.darkBodyMedium : AppTheme.bodyMedium,
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
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