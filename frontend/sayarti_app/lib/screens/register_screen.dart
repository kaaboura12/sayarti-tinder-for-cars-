import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
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
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _firstnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }
  
  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }
  
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      firstname: _firstnameController.text.trim(),
      email: _emailController.text.trim(),
      numerotlf: _phoneController.text.trim(),
      motdepasse: _passwordController.text,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please login.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to login screen
      Navigator.of(context).pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;
    
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
              // Decorative background elements
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
              
              // App bar with back button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Create Account',
                        style: (isDarkMode ? AppTheme.darkHeadingMedium : AppTheme.headingMedium).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
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
                            // Form header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
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
                                  Text(
                                    'Join Sayarti',
                                    style: (isDarkMode ? AppTheme.darkHeadingLarge : AppTheme.headingLarge).copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Create your account to get started',
                                    style: (isDarkMode ? AppTheme.darkBodyMedium : AppTheme.bodyMedium).copyWith(
                                      color: isDarkMode ? AppTheme.darkTextLightColor : AppTheme.textLightColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Form fields
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Name fields in a row
                                    Row(
                                      children: [
                                        // First name
                                        Expanded(
                                          child: CustomTextField(
                                            label: 'First Name',
                                            hint: 'Enter first name',
                                            controller: _firstnameController,
                                            prefixIcon: const Icon(Icons.person_outline),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Last name
                                        Expanded(
                                          child: CustomTextField(
                                            label: 'Last Name',
                                            hint: 'Enter last name',
                                            controller: _nameController,
                                            prefixIcon: const Icon(Icons.person_outline),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Email
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
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Phone number
                                    CustomTextField(
                                      label: 'Phone Number',
                                      hint: 'Enter your phone number',
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: const Icon(Icons.phone_outlined),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Password
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
                                          return 'Please enter a password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Confirm Password
                                    CustomTextField(
                                      label: 'Confirm Password',
                                      hint: 'Confirm your password',
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword 
                                              ? Icons.visibility_outlined 
                                              : Icons.visibility_off_outlined,
                                          color: AppTheme.textLightColor,
                                        ),
                                        onPressed: _toggleConfirmPasswordVisibility,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Error message
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
                                    
                                    // Register button
                                    CustomButton(
                                      text: 'CREATE ACCOUNT',
                                      onPressed: _register,
                                      isLoading: authProvider.isLoading,
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Login option
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account? ',
                                          style: AppTheme.bodyMedium,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'Login',
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
            ],
          ),
        ),
      ),
    );
  }
} 