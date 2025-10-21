class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String userPhoneNumber;
  final String firebaseToken;
  final String createdBy;
  final String createdByName;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.userPhoneNumber,
    required this.firebaseToken,
    required this.createdBy,
    required this.createdByName,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      userPhoneNumber: json['userPhoneNumber'] as String,
      firebaseToken: json['firebaseToken'] as String,
      createdBy: json['createdBy'] as String,
      createdByName: json['createdByName'] as String,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'userPhoneNumber': userPhoneNumber,
      'firebaseToken': firebaseToken,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<NotificationModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => NotificationModel.fromJson(json)).toList();
  }
}
