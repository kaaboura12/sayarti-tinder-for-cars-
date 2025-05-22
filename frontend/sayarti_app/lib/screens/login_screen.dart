import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      motdepasse: _passwordController.text,
    );
    
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final themeData = Theme.of(context);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
              ? [
                  AppTheme.darkSurfaceColor,
                  Colors.black,
                ]
              : [
                  AppTheme.primaryColor.withOpacity(0.9),
                  AppTheme.primaryDarkColor,
                ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              
              // Main content
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top curved area with logo and title
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                    ? AppTheme.primaryColor.withOpacity(0.2)
                                    : AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Car icon in a circle
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor.withOpacity(0.3),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.directions_car,
                                        size: 40,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Sayarti',
                                      style: (isDarkMode ? AppTheme.darkHeadingLarge : AppTheme.headingLarge).copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sign in to your account',
                                      style: (isDarkMode ? AppTheme.darkBodyMedium : AppTheme.bodyMedium).copyWith(
                                        color: isDarkMode ? AppTheme.darkTextLightColor : AppTheme.textLightColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Form area
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Email input
                                      CustomTextField(
                                        label: 'Email',
                                        hint: 'Enter your email',
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        prefixIcon: const Icon(Icons.email_outlined),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Password input
                                      CustomTextField(
                                        label: 'Password',
                                        hint: 'Enter your password',
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword 
                                                ? Icons.visibility_outlined 
                                                : Icons.visibility_off_outlined,
                                            color: AppTheme.textLightColor,
                                          ),
                                          onPressed: _togglePasswordVisibility,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      // Forgot password
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            // Forgot password functionality would go here
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Forgot password functionality coming soon'),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppTheme.textLightColor,
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 30),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            alignment: Alignment.centerRight,
                                          ),
                                          child: const Text('Forgot Password?'),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Error message if login fails
                                      if (authProvider.errorMessage != null)
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.errorColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: AppTheme.errorColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  authProvider.errorMessage!,
                                                  style: TextStyle(
                                                    color: AppTheme.errorColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Login button
                                      CustomButton(
                                        text: 'LOGIN',
                                        onPressed: _login,
                                        isLoading: authProvider.isLoading,
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Sign up option
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Don't have an account? ",
                                            style: AppTheme.bodyMedium,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                              );
                                            },
                                            child: Text(
                                              'Sign up',
                                              style: AppTheme.bodyMedium.copyWith(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 