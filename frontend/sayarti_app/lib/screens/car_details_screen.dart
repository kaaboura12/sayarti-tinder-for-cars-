import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/car_model.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';

class CarDetailsScreen extends StatefulWidget {
  final Car car;
  
  const CarDetailsScreen({Key? key, required this.car}) : super(key: key);

  @override
  _CarDetailsScreenState createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final UserService _userService = UserService();
  User? _seller;
  bool _isLoadingSeller = false;
  
  @override
  void initState() {
    super.initState();
    _loadSellerDetails();
  }
  
  Future<void> _loadSellerDetails() async {
    if (widget.car.addedBy == 0) return;
    
    setState(() {
      _isLoadingSeller = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.token;
      
      if (token != null) {
        final seller = await _userService.getUserById(widget.car.addedBy, token);
        
        if (mounted) {
          setState(() {
            _seller = seller;
            _isLoadingSeller = false;
          });
        }
      }
    } catch (e) {
      print('Failed to load seller details: $e');
      if (mounted) {
        setState(() {
          _isLoadingSeller = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'TND ', decimalDigits: 0);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share car listing
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: widget.car.photos.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: widget.car.photos.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              widget.car.photos[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDarkMode ? Colors.grey[900] : Colors.grey[800],
                                  child: const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : Container(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.car_repair,
                              size: 64,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                            ),
                          ),
                        ),
                ),
                
                // Image indicators
                if (widget.car.photos.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.car.photos.asMap().entries.map((entry) {
                        return GestureDetector(
                          onTap: () => _pageController.animateToPage(
                            entry.key,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(
                                _currentImageIndex == entry.key ? 0.9 : 0.4,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                // Gradient overlay for better visibility of app bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Car details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  Text(
                    widget.car.title,
                    style: isDarkMode
                      ? AppTheme.darkHeadingLarge
                      : const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(widget.car.price),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Condition chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getConditionColor(widget.car.condition).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.car.condition,
                      style: TextStyle(
                        color: _getConditionColor(widget.car.condition),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Key details cards
                  Row(
                    children: [
                      _buildInfoCard(
                        icon: Icons.calendar_today,
                        title: 'Year',
                        value: widget.car.dateMiseEnCirculation.split('-')[0],
                        isDarkMode: isDarkMode,
                      ),
                      _buildInfoCard(
                        icon: Icons.local_gas_station,
                        title: 'Fuel',
                        value: widget.car.carburant,
                        isDarkMode: isDarkMode,
                      ),
                      _buildInfoCard(
                        icon: Icons.speed,
                        title: 'Power',
                        value: '${widget.car.puissanceFiscale} CV',
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Location
                  _buildDetailRow(
                    icon: Icons.location_on,
                    title: 'Location',
                    value: widget.car.location,
                    isDarkMode: isDarkMode,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Listed date
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    title: 'Listed on',
                    value: widget.car.addDate,
                    isDarkMode: isDarkMode,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Description',
                    style: isDarkMode
                      ? AppTheme.darkHeadingMedium
                      : const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                    child: Text(
                      widget.car.description,
                      style: TextStyle(
                        color: isDarkMode ? AppTheme.darkTextColor : Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Call button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Use seller's phone number if available, otherwise use placeholder
                  final phoneNumber = _seller?.numerotlf ?? '+1234567890';
                  _makePhoneCall(phoneNumber);
                },
                icon: const Icon(Icons.phone),
                label: Text(_isLoadingSeller 
                  ? 'Loading...' 
                  : 'Call Seller'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Message button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to messaging screen
                  if (_seller != null && widget.car.id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: widget.car.addedBy,
                          otherUserName: _seller != null 
                              ? "${_seller!.firstname} ${_seller!.name}" 
                              : "Car Seller",
                          carId: widget.car.id!,
                          carTitle: widget.car.title,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot start conversation. Try again later.')),
                    );
                  }
                },
                icon: const Icon(Icons.message),
                label: Text(_isLoadingSeller 
                  ? 'Loading...' 
                  : 'Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppTheme.darkTextColor : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: TextStyle(
            color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? AppTheme.darkTextColor : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'perfect':
        return Colors.teal;
      case 'good used':
        return Colors.orange;
      case 'used':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
  
  Future<void> _makePhoneCall(String phoneNumber) async {
    // Show elegant popup with phone number
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDarkMode = themeProvider.isDarkMode;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
          elevation: 5,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar or icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.phone_rounded,
                    size: 36,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  _seller != null 
                    ? '${_seller!.firstname} ${_seller!.name}'
                    : 'Seller Contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppTheme.darkTextColor : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Phone number (tappable)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phoneNumber)).then((_) {
                      Navigator.of(context).pop(); // Dismiss dialog after copying
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          phoneNumber,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? AppTheme.darkTextColor : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.copy,
                          size: 18,
                          color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Call button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: phoneNumber,
                          );
                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch phone app')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Call'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 