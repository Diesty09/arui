import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role; // 'umkm', 'influencer', 'admin'
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final DateTime? createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      role: data['role'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }
}
