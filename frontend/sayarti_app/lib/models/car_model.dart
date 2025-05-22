class Car {
  final int? id;
  final String title;
  final String brand;
  final String location;
  final String addDate;
  final int addedBy; // user ID of the person who added the car
  final double price;
  final String description;
  final int puissanceFiscale;
  final String carburant; // diesel/essence/electric/hybrid
  final String dateMiseEnCirculation;
  final String condition; // used/goodused/new/perfect
  final List<String> photos;
  
  Car({
    this.id,
    required this.title,
    required this.brand,
    required this.location,
    required this.addDate,
    required this.addedBy,
    required this.price,
    required this.description,
    required this.puissanceFiscale,
    required this.carburant,
    required this.dateMiseEnCirculation,
    required this.condition,
    required this.photos,
  });
  
  factory Car.fromJson(Map<String, dynamic> json) {
    // Helper functions to handle different data types
    double convertPrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          print('Error parsing price: $e');
          return 0.0;
        }
      }
      return 0.0;
    }
    
    int convertInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('Error parsing integer: $e');
          return 0;
        }
      }
      return 0;
    }
    
    return Car(
      id: json['id'] != null ? convertInt(json['id']) : null,
      title: json['title'] ?? '',
      brand: json['brand'] ?? '',
      location: json['location'] ?? '',
      addDate: json['add_date'] ?? json['addDate'] ?? '',
      addedBy: convertInt(json['added_by_id'] ?? json['addedBy'] ?? 0),
      price: convertPrice(json['price']),
      description: json['description'] ?? '',
      puissanceFiscale: convertInt(json['puissance_fiscale'] ?? json['puissanceFiscale'] ?? 0),
      carburant: json['carburant'] ?? '',
      dateMiseEnCirculation: json['date_mise_en_circulation'] ?? json['dateMiseEnCirculation'] ?? '',
      condition: json['condition'] ?? '',
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'brand': brand,
      'location': location,
      'add_date': addDate,
      'added_by_id': addedBy,
      'price': price,
      'description': description,
      'puissance_fiscale': puissanceFiscale,
      'carburant': carburant,
      'date_mise_en_circulation': dateMiseEnCirculation,
      'condition': condition,
      'photos': photos,
    };
  }
} 