import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/car_model.dart';
import '../services/favorite_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../utils/error_handler.dart';
import 'car_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  List<Car>? _favorites;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

      final favorites = await _favoriteService.getFavorites(token);
      
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load favorites: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(Car car) async {
    // Store context in a local variable to avoid context access after widget disposal
    final BuildContext currentContext = context;
    
    try {
      final authProvider = Provider.of<AuthProvider>(currentContext, listen: false);
      final token = await authProvider.token;

      if (token == null) {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(
          currentContext, 
          'Authentication required'
        );
        return;
      }
      
      // Check if car.id is null
      if (car.id == null) {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(
          currentContext, 
          'Cannot remove car from favorites: missing ID'
        );
        return;
      }

      final success = await _favoriteService.removeFromFavorites(car.id!, token);
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _favorites?.removeWhere((favCar) => favCar.id == car.id);
        });
        
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('${car.title} removed from favorites'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                if (car.id != null) {
                  await _favoriteService.addToFavorites(car.id!, token);
                  if (!mounted) return;
                  _loadFavorites();
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ErrorHandler.handleApiError(
        e.toString(), 
        'Failed to remove from favorites'
      );
      ErrorHandler.showErrorSnackBar(currentContext, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final currencyFormat = NumberFormat.currency(symbol: 'TND ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
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
                        onPressed: _loadFavorites,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _favorites == null || _favorites!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorite cars yet',
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
                            'Swipe right on cars you like to add them to favorites',
                            style: isDarkMode
                                ? AppTheme.darkBodyMedium
                                : TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _favorites!.length,
                        itemBuilder: (context, index) {
                          final car = _favorites![index];
                          return _buildFavoriteCarCard(car, isDarkMode, currencyFormat);
                        },
                      ),
                    ),
    );
  }

  Widget _buildFavoriteCarCard(Car car, bool isDarkMode, NumberFormat currencyFormat) {
    return Card(
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarDetailsScreen(car: car),
            ),
          ).then((_) => _loadFavorites());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car image with price tag
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: car.photos.isNotEmpty
                      ? Image.network(
                          car.photos[0],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                              child: Icon(
                                Icons.car_repair,
                                size: 64,
                                color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 180,
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          child: Icon(
                            Icons.car_repair,
                            size: 64,
                            color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                          ),
                        ),
                ),
                // Price tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      currencyFormat.format(car.price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                // Condition tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getConditionColor(car.condition),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
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
                // Remove from favorites
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeFavorite(car),
                      tooltip: 'Remove from favorites',
                    ),
                  ),
                ),
              ],
            ),
            // Car details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    car.title,
                    style: isDarkMode
                        ? AppTheme.darkHeadingMedium
                        : const TextStyle(
                            fontSize: 18,
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
                      Text(
                        car.location,
                        style: TextStyle(
                          color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Car specs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSpecItem(
                        icon: Icons.calendar_today,
                        value: car.dateMiseEnCirculation.split('-')[0],
                        isDarkMode: isDarkMode,
                      ),
                      _buildSpecItem(
                        icon: Icons.local_gas_station,
                        value: car.carburant,
                        isDarkMode: isDarkMode,
                      ),
                      _buildSpecItem(
                        icon: Icons.speed,
                        value: '${car.puissanceFiscale} CV',
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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
} 