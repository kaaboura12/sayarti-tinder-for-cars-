import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/car_model.dart';
import '../services/car_service.dart';
import '../services/favorite_service.dart';
import '../utils/app_theme.dart';
import '../utils/error_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/futuristic_navbar.dart';
import 'car_details_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class CarSwipeScreen extends StatefulWidget {
  const CarSwipeScreen({Key? key}) : super(key: key);

  @override
  _CarSwipeScreenState createState() => _CarSwipeScreenState();
}

class _CarSwipeScreenState extends State<CarSwipeScreen> with SingleTickerProviderStateMixin {
  final CarService _carService = CarService();
  final FavoriteService _favoriteService = FavoriteService();
  final CardSwiperController _swiperController = CardSwiperController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Car>? _cars;
  List<Car>? _allCars; // Store all cars for filtering locally
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  int _currentIndex = 0;
  int _currentImageIndex = 0;
  int _currentNavIndex = 2; // Buy tab index
  
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
    _loadCars();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.token;
      
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }
      
      final cars = await _carService.getCars(token);
      
      if (mounted) {
        setState(() {
          _cars = cars;
          _allCars = List.from(cars); // Store all cars for filtering
          _isLoading = false;
          _currentImageIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load cars: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // Method to search cars by title
  Future<void> _searchCars(String query) async {
    if (query.isEmpty) {
      // If search is cleared, restore all cars
      setState(() {
        _cars = _allCars;
        _currentIndex = 0;
        _currentImageIndex = 0;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.token;
      
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }
      
      final cars = await _carService.searchCarsByTitle(query, token);
      
      if (mounted) {
        setState(() {
          _cars = cars;
          _isLoading = false;
          _currentIndex = 0;
          _currentImageIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Search failed: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // Show search dialog
  void _showSearchDialog() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
          title: Text(
            'Search Cars',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter car title...',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.primaryColor,
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onSubmitted: (value) {
              Navigator.pop(context);
              _searchCars(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _searchCars(_searchController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Search'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _addToFavorites(Car car) async {
    // Create a local reference to the context to avoid context loss when widget is disposed
    final BuildContext currentContext = context;
    
    try {
      final authProvider = Provider.of<AuthProvider>(currentContext, listen: false);
      final token = await authProvider.token;
      
      if (token == null) {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(
          currentContext, 
          'Authentication required to add to favorites'
        );
        return;
      }
      
      if (car.id == null) {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(
          currentContext, 
          'Cannot add car to favorites: missing ID'
        );
        return;
      }
      
      final success = await _favoriteService.addToFavorites(car.id!, token);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white),
                const SizedBox(width: 10),
                Text('${car.title} added to favorites'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ErrorHandler.showErrorSnackBar(
          currentContext, 
          'Failed to add to favorites'
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ErrorHandler.handleApiError(
        e.toString(), 
        'Error adding to favorites'
      );
      ErrorHandler.showErrorSnackBar(currentContext, errorMessage);
    }
  }
  
  void _handleNavigation(int index) {
    if (index != _currentNavIndex) {
      setState(() => _currentNavIndex = index);
    
      if (index == 0) {
        // Navigate to home
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else if (index == 3) {
        // Navigate to profile
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else if (index == 1) {
        // Show snackbar for Sell tab
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_navItems[index].label} feature coming soon!')),
        );
      }
    }
  }
  
  void _nextImage() {
    if (_cars != null && _cars!.isNotEmpty) {
      setState(() {
        if (_currentImageIndex < _cars![_currentIndex].photos.length - 1) {
          _currentImageIndex++;
        } else {
          _currentImageIndex = 0;
        }
      });
    }
  }
  
  void _viewCarDetails(Car car) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CarDetailsScreen(car: car),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700; // Check for small screens
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[100],
      extendBody: true, // Important for the floating navbar
      appBar: AppBar(
        title: !_isSearching 
          ? const Text('Find Cars', style: TextStyle(fontWeight: FontWeight.bold))
          : TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search cars...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                setState(() {
                  _isSearching = false;
                });
                _searchCars(value);
              },
            ),
        centerTitle: true,
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : null,
        elevation: 0,
        flexibleSpace: isDarkMode 
          ? null
          : Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (_isSearching) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  // Restore all cars
                  _cars = _allCars;
                });
              } else {
                _showSearchDialog();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading cars...',
                    style: isDarkMode ? AppTheme.darkBodyMedium : null,
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadCars,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _cars == null || _cars!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.car_rental,
                            size: 64,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cars found',
                            style: isDarkMode 
                              ? AppTheme.darkHeadingMedium.copyWith(fontSize: 18)
                              : TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isNotEmpty 
                              ? 'No results match your search'
                              : 'Pull down to refresh or check back later',
                            style: isDarkMode
                              ? AppTheme.darkBodyMedium
                              : TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _searchController.text.isNotEmpty
                              ? () {
                                  _searchController.clear();
                                  _loadCars();
                                }
                              : _loadCars,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(_searchController.text.isNotEmpty ? 'Clear Search' : 'Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCars,
                      color: AppTheme.primaryColor,
                      child: Stack(
                        children: [
                          // Main content - Card swiper
                          Padding(
                            padding: const EdgeInsets.only(bottom: 100.0), // Space for navbar
                            child: SizedBox(
                              height: isSmallScreen ? screenSize.height - 180 : screenSize.height - 200,
                              child: CardSwiper(
                                controller: _swiperController,
                                cardsCount: _cars!.length,
                                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                                  final car = _cars![index];
                                  if (index == _currentIndex) {
                                    _currentImageIndex = _currentImageIndex.clamp(0, car.photos.length - 1);
                                  }
                                  return _buildCarCard(car, index);
                                },
                                onSwipe: (previousIndex, currentIndex, direction) {
                                  setState(() {
                                    _currentIndex = currentIndex ?? 0;
                                    _currentImageIndex = 0;
                                  });
                                  
                                  if (previousIndex < _cars!.length) {
                                    final swipedCar = _cars![previousIndex];
                                    
                                    if (direction == CardSwiperDirection.right) {
                                      // When swiping right, only add to favorites
                                      _addToFavorites(swipedCar);
                                    }
                                  }
                                  return true;
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                allowedSwipeDirection: const AllowedSwipeDirection.only(
                                  left: true, 
                                  right: true
                                ),
                                scale: 0.95, // Add scale parameter for better visual hierarchy
                                duration: const Duration(milliseconds: 300), // Ensure smooth animation
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
      // Futuristic floating navigation bar
      bottomNavigationBar: FuturisticNavBar(
        currentIndex: _currentNavIndex,
        onTabSelected: _handleNavigation,
        items: _navItems,
      ),
    );
  }
  
  Widget _buildCarCard(Car car, int index) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final currencyFormat = NumberFormat.currency(symbol: 'TND ', decimalDigits: 0);
    final screenSize = MediaQuery.of(context).size;
    final isActive = index == _currentIndex;
    final isSmallScreen = screenSize.height < 700; // Check for small screens
    
    return GestureDetector(
      onTap: () => _viewCarDetails(car),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car image with interactive gallery
              GestureDetector(
                onTap: _nextImage,
                child: Stack(
                  children: [
                    // Main car image
                    SizedBox(
                      height: isSmallScreen ? screenSize.height * 0.30 : screenSize.height * 0.35, // Adjust height based on screen size
                      width: double.infinity,
                      child: car.photos.isNotEmpty
                          ? Image.network(
                              car.photos[_currentImageIndex >= car.photos.length ? 0 : _currentImageIndex],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                  child: Center(
                                    child: Icon(
                                      Icons.car_repair,
                                      size: 64,
                                      color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  Icons.car_repair,
                                  size: 64,
                                  color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                                ),
                              ),
                            ),
                    ),
                    
                    // Image gallery indicators
                    if (car.photos.length > 1)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: car.photos.asMap().entries.map((entry) {
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == entry.key
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    
                    // Tap indicator for next image
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.white,
                              size: isActive ? 20 : 0, // Only show on active card
                            ),
                            if (isActive) // Only show text on active card
                              const SizedBox(width: 4),
                            if (isActive) // Only show text on active card
                              const Text(
                                'Tap to view more',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Price tag
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          currencyFormat.format(car.price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    // Car condition tag
                    Positioned(
                      bottom: 40,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getConditionColor(car.condition),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          car.condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Car details section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        car.title,
                        style: isDarkMode
                            ? AppTheme.darkHeadingMedium.copyWith(fontSize: isSmallScreen ? 18 : 20)
                            : TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Location with icon
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              car.location,
                              style: TextStyle(
                                color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Car specs grid - Wrap in Flexible to prevent overflow
                      Flexible(
                        child: Row(
                          children: [
                            _buildSpecItem(
                              icon: Icons.calendar_today,
                              label: 'Year',
                              value: car.dateMiseEnCirculation.split('-')[0],
                              isDarkMode: isDarkMode,
                            ),
                            _buildSpecItem(
                              icon: Icons.local_gas_station,
                              label: 'Fuel',
                              value: car.carburant,
                              isDarkMode: isDarkMode,
                            ),
                            _buildSpecItem(
                              icon: Icons.speed,
                              label: 'Power',
                              value: '${car.puissanceFiscale} CV',
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                      ),
                      
                      // Swipe instructions - Make it fit within a fixed size
                      Container(
                        height: 36,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swipe_left,
                              color: Colors.red.withOpacity(0.7),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.red.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.swipe_right,
                              color: Colors.green.withOpacity(0.7),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add to Favorites',
                              style: TextStyle(
                                color: Colors.green.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    // Get screen size to check if we're on a small screen
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: isSmallScreen ? 16 : 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppTheme.darkTextColor : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
} 