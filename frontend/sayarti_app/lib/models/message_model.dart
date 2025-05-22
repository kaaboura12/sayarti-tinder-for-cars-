class Message {
  final int? id;
  final int senderId;
  final int receiverId;
  final int carId;
  final String message;
  final bool isRead;
  final String createdAt;
  final String? senderName;
  final String? senderFirstname;
  final String? receiverName;
  final String? receiverFirstname;
  
  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.carId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.senderName,
    this.senderFirstname,
    this.receiverName,
    this.receiverFirstname,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      carId: json['car_id'],
      message: json['message'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'],
      senderName: json['sender_name'],
      senderFirstname: json['sender_firstname'],
      receiverName: json['receiver_name'],
      receiverFirstname: json['receiver_firstname'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'car_id': carId,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt,
      'sender_name': senderName,
      'sender_firstname': senderFirstname,
      'receiver_name': receiverName,
      'receiver_firstname': receiverFirstname,
    };
  }
} 