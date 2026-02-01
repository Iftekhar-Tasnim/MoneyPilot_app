class NotificationModel {
  final int? id;
  final String title;
  final String message;
  final String type; // 'budget', 'loan', 'milestone'
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      type: map['type'],
      isRead: map['isRead'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
