class Conversation {
  final int id;
  final int carId;
  final String carTitle;
  final String? carPhoto;
  final int otherUserId;
  final String otherUserName;
  final String otherUserFirstname;
  final String? lastMessageTime;
  final String? lastMessage;
  
  Conversation({
    required this.id,
    required this.carId,
    required this.carTitle,
    this.carPhoto,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserFirstname,
    this.lastMessageTime,
    this.lastMessage,
  });
  
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      carId: json['car_id'],
      carTitle: json['car_title'] ?? 'Unknown car',
      carPhoto: json['car_photos'],
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'] ?? '',
      otherUserFirstname: json['other_user_firstname'] ?? '',
      lastMessageTime: json['last_message_time'],
      lastMessage: json['last_message'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'car_id': carId,
      'car_title': carTitle,
      'car_photos': carPhoto,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_firstname': otherUserFirstname,
      'last_message_time': lastMessageTime,
      'last_message': lastMessage,
    };
  }
} 