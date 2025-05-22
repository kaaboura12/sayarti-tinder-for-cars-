class Notification {
  final int id;
  final String title;
  final String message;
  final String type;
  final int? targetId;
  final bool isRead;
  final String createdAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetId,
    required this.isRead,
    required this.createdAt
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    // Handle is_read which can be bool, int (0/1), or null
    bool isReadValue = false;
    final isReadField = json['is_read'];
    
    if (isReadField != null) {
      if (isReadField is bool) {
        isReadValue = isReadField;
      } else if (isReadField is int) {
        isReadValue = isReadField == 1;
      } else if (isReadField is String) {
        isReadValue = isReadField.toLowerCase() == 'true' || isReadField == '1';
      }
    }
    
    return Notification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      targetId: json['target_id'],
      isRead: isReadValue,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'target_id': targetId,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }
} 