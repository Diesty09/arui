import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String campaignId;
  final String umkmId;
  final String influencerId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime? createdAt;

  ChatModel({
    required this.chatId,
    required this.campaignId,
    required this.umkmId,
    required this.influencerId,
    this.lastMessage,
    this.lastMessageTime,
    this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ChatModel(
      chatId: documentId,
      campaignId: data['campaignId'] ?? '',
      umkmId: data['umkmId'] ?? '',
      influencerId: data['influencerId'] ?? '',
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'umkmId': umkmId,
      'influencerId': influencerId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime? createdAt;
  final bool isRead;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageModel(
      messageId: documentId,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
