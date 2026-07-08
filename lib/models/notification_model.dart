import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final String type; // 'chat', 'offer_status', 'payment_status'
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      notificationId: documentId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
