import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import '../models/car_model.dart';

class CarService {
  // Use same baseUrl pattern as auth_service
  final String baseUrl = kIsWeb 
    ? 'http://localhost:5000/api' 
    : 'http://10.0.2.2:5000/api';
  
  // Fetch car listings with optional filters
  Future<List<Car>> getCars(String token, {Map<String, dynamic>? filters}) async {
    try {
      Uri uri = Uri.parse('$baseUrl/cars');
      
      // Add query parameters if filters exist
      if (filters != null && filters.isNotEmpty) {
        uri = uri.replace(queryParameters: 
          filters.map((key, value) => MapEntry(key, value.toString())));
      }
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        try {
          final List<dynamic> carsJson = jsonDecode(response.body);
          return carsJson.map((json) {
            try {
              return Car.fromJson(json);
            } catch (e) {
              print('Error parsing car data: $e');
              print('Problem JSON: $json');
              return Car(
                id: null,
                title: 'Error parsing car',
                brand: '',
                location: '',
                addDate: '',
                addedBy: 0,
                price: 0,
                description: 'There was an error loading this car data',
                puissanceFiscale: 0,
                carburant: '',
                dateMiseEnCirculation: '',
                condition: '',
                photos: [],
              );
            }
          }).toList();
        } catch (e) {
          print('Error parsing cars response: $e');
          print('Response body: ${response.body}');
          return [];
        }
      } else {
        print('Error fetching cars: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception when fetching cars: $e');
      return [];
    }
  }
  
  Future<bool> addCar(Car car, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cars'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(car.toJson()),
      );
      
      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error adding car: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception when adding car: $e');
      return false;
    }
  }
  
  // Function to upload car images - platform aware implementation
  Future<List<String>> uploadCarImages(List<dynamic> images, String token) async {
    List<String> uploadedImageUrls = [];
    
    try {
      if (kIsWeb) {
        // Web implementation 
        for (var image in images) {
          final uri = Uri.parse('$baseUrl/upload');
          
          // For debugging
          print('Uploading image of type: ${image.runtimeType}');
          
          Uint8List? imageBytes;
          String filename = 'image.jpg';
          
          // Handle different image types
          if (image is Uint8List) {
            imageBytes = image;
          } else if (image is Future<Uint8List>) {
            // If it's a future, await it
            try {
              imageBytes = await image;
            } catch (e) {
              print('Error awaiting image bytes: $e');
              continue;
            }
          } else if (image is File) {
            try {
              imageBytes = await image.readAsBytes();
            } catch (e) {
              print('Error reading file bytes: $e');
              continue;
            }
          } else {
            // Skip unknown types
            print('Unknown image type: ${image.runtimeType}');
            continue;
          }
          
          if (imageBytes == null) {
            print('Failed to get image bytes');
            continue;
          }
          
          // Create multipart request
          var request = http.MultipartRequest('POST', uri);
          request.headers['Authorization'] = 'Bearer $token';
          
          // Add file bytes
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageBytes,
              filename: filename,
              contentType: MediaType('image', 'jpeg'),
            )
          );
          
          // Send the request
          try {
            var streamedResponse = await request.send();
            var response = await http.Response.fromStream(streamedResponse);
            
            print('Upload response status: ${response.statusCode}');
            print('Upload response body: ${response.body}');
            
            if (response.statusCode == 200) {
              var responseData = jsonDecode(response.body);
              uploadedImageUrls.add(responseData['imageUrl']);
            } else {
              print('Failed to upload image: ${response.body}');
            }
          } catch (e) {
            print('Error sending request: $e');
          }
        }
      } else {
        // Mobile implementation using dart:io
        for (var image in images) {
          if (image is File) {
            final uri = Uri.parse('$baseUrl/upload');
            var request = http.MultipartRequest('POST', uri);
            
            request.headers['Authorization'] = 'Bearer $token';
            
            // Add the image file to the request
            var pic = await http.MultipartFile.fromPath('image', image.path);
            request.files.add(pic);
            
            // Send the request and get the response
            try {
              var streamedResponse = await request.send();
              var response = await http.Response.fromStream(streamedResponse);
              
              print('Mobile upload response status: ${response.statusCode}');
              print('Mobile upload response body: ${response.body}');
              
              if (response.statusCode == 200) {
                var responseData = jsonDecode(response.body);
                uploadedImageUrls.add(responseData['imageUrl']);
              } else {
                print('Failed to upload image: ${response.body}');
              }
            } catch (e) {
              print('Error sending request: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Exception when uploading images: $e');
    }
    
    return uploadedImageUrls;
  }

  // Dedicated method for searching cars by title
  Future<List<Car>> searchCarsByTitle(String searchQuery, String token) async {
    try {
      final filters = {'search': searchQuery};
      return await getCars(token, filters: filters);
    } catch (e) {
      print('Exception when searching cars: $e');
      return [];
    }
  }
} 