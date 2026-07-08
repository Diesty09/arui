import 'package:cloud_firestore/cloud_firestore.dart';

class UmkmProfileModel {
  final String uid;
  final String businessName;
  final String ownerName;
  final String category;
  final String address;
  final String description;
  final String phone;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UmkmProfileModel({
    required this.uid,
    required this.businessName,
    required this.ownerName,
    required this.category,
    required this.address,
    required this.description,
    required this.phone,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UmkmProfileModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UmkmProfileModel(
      uid: documentId,
      businessName: data['businessName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      category: data['category'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      phone: data['phone'] ?? '',
      logoUrl: data['logoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'ownerName': ownerName,
      'category': category,
      'address': address,
      'description': description,
      'phone': phone,
      'logoUrl': logoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
