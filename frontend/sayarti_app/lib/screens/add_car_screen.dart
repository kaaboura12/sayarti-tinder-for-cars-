import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/car_model.dart';
import '../services/car_service.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({Key? key}) : super(key: key);

  @override
  _AddCarScreenState createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carService = CarService();
  final _imagePicker = ImagePicker();
  
  String _title = '';
  String _brand = '';
  String _location = 'Tunis'; // Default location
  double _price = 0;
  String _description = '';
  int _puissanceFiscale = 0;
  String _carburant = 'Diesel';
  DateTime _dateMiseEnCirculation = DateTime.now();
  String _condition = 'Used';
  List<dynamic> _selectedImages = [];
  bool _isLoading = false;
  final _scrollController = ScrollController();
  
  final List<String> _carburantOptions = ['Diesel', 'Essence', 'Electric', 'Hybrid'];
  final List<String> _conditionOptions = ['Used', 'Good Used', 'New', 'Perfect'];
  final List<String> _locationOptions = [
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Zaghouan',
    'Bizerte',
    'Béja',
    'Jendouba',
    'Kef',
    'Siliana',
    'Sousse',
    'Monastir',
    'Mahdia',
    'Kairouan',
    'Kasserine',
    'Sidi Bouzid',
    'Sfax',
    'Gafsa',
    'Tozeur',
    'Kebili',
    'Gabès',
    'Médenine',
    'Tataouine'
  ];
  
  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        if (kIsWeb) {
          // For web platform, immediately read the bytes instead of creating Futures
          for (var xFile in pickedFiles) {
            xFile.readAsBytes().then((data) {
              setState(() {
                _selectedImages.add(data);
              });
            });
          }
        } else {
          // For mobile platforms
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)).toList());
        }
      });
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateMiseEnCirculation,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateMiseEnCirculation) {
      setState(() {
        _dateMiseEnCirculation = picked;
      });
    }
  }
  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add at least one image of your car'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = await authProvider.token;
        final userId = authProvider.user?.id;
        
        if (token == null || userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You must be logged in to add a car'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        // Add debug print statements
        print('Uploading ${_selectedImages.length} images');
        for (var i = 0; i < _selectedImages.length; i++) {
          print('Image ${i+1} type: ${_selectedImages[i].runtimeType}');
        }
        
        // Upload images first
        final imageUrls = await _carService.uploadCarImages(_selectedImages, token);
        
        print('Received ${imageUrls.length} image URLs: $imageUrls');
        
        if (imageUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload images. Please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        // Create car object with location from dropdown
        final car = Car(
          title: _title,
          brand: _brand,
          location: _location, // Location is already set from dropdown
          price: _price,
          description: _description,
          puissanceFiscale: _puissanceFiscale,
          carburant: _carburant,
          dateMiseEnCirculation: DateFormat('yyyy-MM-dd').format(_dateMiseEnCirculation),
          condition: _condition,
          addDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          addedBy: userId,
          photos: imageUrls,
        );
        
        // Save car
        final success = await _carService.addCar(car, token);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Car added successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add car. Please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to show the location selector dialog
  void _showLocationSelector() {
    String searchQuery = '';
    List<String> filteredLocations = List.from(_locationOptions);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Location'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                          filteredLocations = _locationOptions
                              .where((location) => location.toLowerCase().contains(searchQuery))
                              .toList();
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredLocations.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredLocations[index]),
                            onTap: () {
                              this.setState(() {
                                _location = filteredLocations[index];
                              });
                              Navigator.pop(context);
                            },
                            trailing: _location == filteredLocations[index]
                                ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        title: const Text('Sell Your Car', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
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
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                  title: Text(
                    'Selling Tips',
                    style: isDarkMode ? AppTheme.darkHeadingMedium : TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Add high-quality photos and detailed information to increase your chances of selling your car quickly.',
                    style: isDarkMode ? AppTheme.darkBodyMedium : null,
                  ),
                  actions: [
                    TextButton(
                      child: Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Uploading your car details...',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDarkMode
                          ? [
                              AppTheme.darkSurfaceColor,
                              AppTheme.darkBackgroundColor,
                            ]
                          : [
                              AppTheme.primaryColor.withOpacity(0.1),
                              Colors.white,
                            ],
                        stops: const [0.0, 0.3],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Your Car Details',
                            style: isDarkMode
                              ? AppTheme.darkHeadingLarge.copyWith(fontSize: 22)
                              : TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Complete the form below with accurate information about your vehicle',
                            style: isDarkMode
                              ? AppTheme.darkBodyMedium.copyWith(fontSize: 14)
                              : TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Images section
                          _buildSectionTitle('Car Images', Icons.photo_library),
                          _buildImageSelector(),
                                 
                          SizedBox(height: 32),

                          // Basic information
                          _buildSectionTitle('Basic Information', Icons.info_outline),
                          SizedBox(height: 16),
                          _buildTextField(
                            label: 'Title',
                            hint: 'e.g., BMW X5 2020 Full Option',
                            icon: Icons.title,
                            onSaved: (value) => _title = value!,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            label: 'Brand',
                            hint: 'e.g., BMW, Mercedes, Toyota',
                            icon: Icons.directions_car,
                            onSaved: (value) => _brand = value!,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a brand';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildLocationSelector(),
                          SizedBox(height: 16),
                          _buildPriceField(),
                          
                          SizedBox(height: 32),
                          
                          // Technical details
                          _buildSectionTitle('Technical Details', Icons.settings),
                          SizedBox(height: 16),
                          _buildTextField(
                            label: 'CV (Puissance Fiscale)',
                            hint: 'e.g., 8',
                            icon: Icons.speed,
                            keyboardType: TextInputType.number,
                            onSaved: (value) => _puissanceFiscale = int.tryParse(value!) ?? 0,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter CV';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildDropdown(
                            label: 'Fuel Type',
                            icon: Icons.local_gas_station,
                            value: _carburant,
                            items: _carburantOptions,
                            onChanged: (value) {
                              setState(() {
                                _carburant = value!;
                              });
                            },
                          ),
                          SizedBox(height: 16),
                          _buildDatePicker(
                            label: 'First Registration Date',
                            icon: Icons.calendar_today,
                            value: _dateMiseEnCirculation,
                            onTap: () => _selectDate(context),
                          ),
                          SizedBox(height: 16),
                          _buildDropdown(
                            label: 'Condition',
                            icon: Icons.auto_fix_high,
                            value: _condition,
                            items: _conditionOptions,
                            onChanged: (value) {
                              setState(() {
                                _condition = value!;
                              });
                            },
                          ),
                          
                          SizedBox(height: 32),
                          
                          // Description
                          _buildSectionTitle('Description', Icons.description),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextFormField(
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Describe your car, its features, and condition...',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                                  child: Icon(Icons.description, color: AppTheme.primaryColor),
                                ),
                              ),
                              onSaved: (value) => _description = value!,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          SizedBox(height: 40),
                          
                          // Submit button
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle),
                                  SizedBox(width: 8),
                                  Text(
                                    'SUBMIT LISTING',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 22,
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: isDarkMode
            ? AppTheme.darkHeadingMedium.copyWith(
                fontSize: 18,
              )
            : TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
      ],
    );
  }
  
  Widget _buildImageSelector() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected images
          if (_selectedImages.isNotEmpty)
            Container(
              height: 120,
              margin: EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12, top: 8),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                          image: DecorationImage(
                            image: _getImageProvider(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          
          // Add image button
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  strokeWidth: 1.5,
                  gap: 5.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_a_photo,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add Photos',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get the appropriate image provider for different platforms
  ImageProvider _getImageProvider(dynamic image) {
    if (kIsWeb) {
      if (image is Uint8List) {
        return MemoryImage(image);
      } 
      // For web, we'll get a Future<Uint8List> because of the async operation
      else if (image is Future<Uint8List>) {
        // Create a placeholder using a colored box
        return MemoryImage(Uint8List.fromList([
          0xFF, 0xC0, 0xC0, 0xC0, // Light gray color
          0xFF, 0xC0, 0xC0, 0xC0,
          0xFF, 0xC0, 0xC0, 0xC0,
          0xFF, 0xC0, 0xC0, 0xC0,
        ]));
      }
      return const NetworkImage('https://via.placeholder.com/100');
    } else {
      if (image is File) {
        return FileImage(image);
      }
      return const NetworkImage('https://via.placeholder.com/100');
    }
  }
  
  Widget _buildTextField({
    required String label,
    required String hint,
    required Function(String?) onSaved,
    required String? Function(String?) validator,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
          filled: true,
          fillColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        style: isDarkMode ? AppTheme.darkBodyMedium : null,
        keyboardType: keyboardType,
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }
  
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: value,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                    color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                style: isDarkMode
                  ? AppTheme.darkBodyMedium
                  : TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                dropdownColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                menuMaxHeight: 300,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMMM yyyy').format(value),
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Icon(
                Icons.arrow_drop_down,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return GestureDetector(
      onTap: _showLocationSelector,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _location,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Icon(
                Icons.arrow_drop_down,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom price input field with TND currency
  Widget _buildPriceField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Price',
          labelStyle: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
          hintText: 'e.g., 50000',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.monetization_on, color: AppTheme.primaryColor),
          suffixText: 'TND',
          suffixStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        onSaved: (value) => _price = double.tryParse(value?.replaceAll(',', '.') ?? '') ?? 0,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a price';
          }
          
          final normalizedValue = value.replaceAll(',', '.');
          if (double.tryParse(normalizedValue) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double dashWidth = 10;
    double dashSpace = gap;
    double radius = 12;

    // Top line
    double x = 0;
    double y = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y + radius),
        Offset(x + dashWidth < size.width - radius ? x + dashWidth : size.width - radius, y + radius),
        paint,
      );
      x += dashWidth + dashSpace;
    }

    // Right line
    x = size.width - radius;
    y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + dashWidth < size.height - radius ? y + dashWidth : size.height - radius),
        paint,
      );
      y += dashWidth + dashSpace;
    }

    // Bottom line
    x = size.width;
    y = size.height - radius;
    while (x > 0) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x - dashWidth > radius ? x - dashWidth : radius, y),
        paint,
      );
      x -= dashWidth + dashSpace;
    }

    // Left line
    x = radius;
    y = size.height;
    while (y > 0) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y - dashWidth > radius ? y - dashWidth : radius),
        paint,
      );
      y -= dashWidth + dashSpace;
    }

    // Draw the corners with solid arc lines
    final rect1 = Rect.fromLTRB(0, 0, radius * 2, radius * 2);
    canvas.drawArc(rect1, 180 * (3.14/180), 90 * (3.14/180), false, paint);
    
    final rect2 = Rect.fromLTRB(size.width - radius * 2, 0, size.width, radius * 2);
    canvas.drawArc(rect2, 270 * (3.14/180), 90 * (3.14/180), false, paint);
    
    final rect3 = Rect.fromLTRB(size.width - radius * 2, size.height - radius * 2, size.width, size.height);
    canvas.drawArc(rect3, 0, 90 * (3.14/180), false, paint);
    
    final rect4 = Rect.fromLTRB(0, size.height - radius * 2, radius * 2, size.height);
    canvas.drawArc(rect4, 90 * (3.14/180), 90 * (3.14/180), false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
} 