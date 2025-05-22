import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'car_details_screen.dart';

class ViewCarsScreen extends StatefulWidget {
  const ViewCarsScreen({Key? key}) : super(key: key);

  @override
  _ViewCarsScreenState createState() => _ViewCarsScreenState();
}

class _ViewCarsScreenState extends State<ViewCarsScreen> {
  final CarService _carService = CarService();
  List<Car>? _cars;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filters
  String? _selectedBrand;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCondition;
  String? _selectedFuelType;
  
  final List<String> _carburantOptions = ['Diesel', 'Essence', 'Electric', 'Hybrid'];
  final List<String> _conditionOptions = ['Used', 'Good Used', 'New', 'Perfect'];
  
  @override
  void initState() {
    super.initState();
    _loadCars();
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
      
      final cars = await _carService.getCars(token, filters: _buildFilters());
      
      if (mounted) {
        setState(() {
          _cars = cars;
          _isLoading = false;
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
  
  Map<String, dynamic> _buildFilters() {
    final filters = <String, dynamic>{};
    
    if (_selectedBrand != null) filters['brand'] = _selectedBrand;
    if (_minPrice != null) filters['minPrice'] = _minPrice;
    if (_maxPrice != null) filters['maxPrice'] = _maxPrice;
    if (_selectedCondition != null) filters['condition'] = _selectedCondition;
    if (_selectedFuelType != null) filters['carburant'] = _selectedFuelType;
    
    return filters;
  }
  
  void _applyFilters() {
    _loadCars();
  }
  
  void _resetFilters() {
    setState(() {
      _selectedBrand = null;
      _minPrice = null;
      _maxPrice = null;
      _selectedCondition = null;
      _selectedFuelType = null;
    });
    _loadCars();
  }
  
  void _showFilterModal() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Cars',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView(
                      children: [
                        // Brand filter
                        Text(
                          'Brand',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          onChanged: (value) {
                            setModalState(() {
                              _selectedBrand = value.isEmpty ? null : value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter brand name',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Price range
                        Text(
                          'Price Range',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setModalState(() {
                                    _minPrice = value.isEmpty ? null : double.tryParse(value);
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Min',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setModalState(() {
                                    _maxPrice = value.isEmpty ? null : double.tryParse(value);
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Max',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Condition filter
                        Text(
                          'Condition',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCondition,
                              isExpanded: true,
                              hint: Text('Select condition', style: TextStyle(color: Colors.grey[400])),
                              dropdownColor: Colors.grey[800],
                              style: const TextStyle(color: Colors.white),
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedCondition = value;
                                });
                              },
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Any condition'),
                                ),
                                ..._conditionOptions.map((condition) {
                                  return DropdownMenuItem<String>(
                                    value: condition,
                                    child: Text(condition),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Fuel type filter
                        Text(
                          'Fuel Type',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFuelType,
                              isExpanded: true,
                              hint: Text('Select fuel type', style: TextStyle(color: Colors.grey[400])),
                              dropdownColor: Colors.grey[800],
                              style: const TextStyle(color: Colors.white),
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedFuelType = value;
                                });
                              },
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Any fuel type'),
                                ),
                                ..._carburantOptions.map((fuel) {
                                  return DropdownMenuItem<String>(
                                    value: fuel,
                                    child: Text(fuel),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Car Listings'),
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : null,
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
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ))
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
                            'Try adjusting your filters or check back later',
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
                      onRefresh: _loadCars,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _cars!.length,
                        itemBuilder: (context, index) {
                          final car = _cars![index];
                          return _buildCarCard(car, isDarkMode);
                        },
                      ),
                    ),
    );
  }
  
  Widget _buildCarCard(Car car, bool isDarkMode) {
    final currencyFormat = NumberFormat.currency(symbol: 'TND ', decimalDigits: 0);
    
    return Card(
      elevation: 4,
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: car.photos.isNotEmpty
                  ? Image.network(
                      car.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.car_repair,
                              size: 48,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
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
                          size: 48,
                          color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                    ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        car.title,
                        style: isDarkMode
                          ? AppTheme.darkHeadingMedium.copyWith(fontSize: 18)
                          : const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(car.price),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Key details
                Row(
                  children: [
                    _buildDetailItem(Icons.location_on, car.location, isDarkMode),
                    _buildDetailItem(Icons.calendar_today, car.dateMiseEnCirculation, isDarkMode),
                    _buildDetailItem(Icons.local_gas_station, car.carburant, isDarkMode),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Condition and listed date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getConditionColor(car.condition).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        car.condition,
                        style: TextStyle(
                          color: _getConditionColor(car.condition),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Listed on: ${car.addDate}',
                        style: TextStyle(
                          color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // View details button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CarDetailsScreen(car: car),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(IconData icon, String text, bool isDarkMode) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: isDarkMode ? AppTheme.darkTextColor : Colors.grey[800],
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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