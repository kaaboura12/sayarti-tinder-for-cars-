class User {
  final int? id;
  final String name;
  final String firstname;
  final String email;
  final String numerotlf;
  
  User({
    this.id,
    required this.name,
    required this.firstname,
    required this.email,
    required this.numerotlf,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : null,
      name: json['name'] ?? '',
      firstname: json['firstname'] ?? '',
      email: json['email'] ?? '',
      numerotlf: json['numerotlf'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'firstname': firstname,
      'email': email,
      'numerotlf': numerotlf,
    };
  }
} 