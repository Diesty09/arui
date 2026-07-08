import 'package:cloud_firestore/cloud_firestore.dart';

class InfluencerProfileModel {
  final String uid;
  final String fullName;
  final String contentCategory;
  final String socialPlatform;
  final String socialUsername;
  final int followers;
  final double engagementRate;
  final double priceRate;
  final String? portfolioUrl;
  final String description;
  final String? photoUrl;
  final double averageRating;
  final int totalReviews;
  // Payment account info
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  // Address & contact (whatsappNumber hanya untuk admin)
  final String? address;
  final String? postalCode;
  final String? whatsappNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isBlacklisted;

  InfluencerProfileModel({
    required this.uid,
    required this.fullName,
    required this.contentCategory,
    required this.socialPlatform,
    required this.socialUsername,
    required this.followers,
    this.engagementRate = 0.0,
    required this.priceRate,
    this.portfolioUrl,
    required this.description,
    this.photoUrl,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.address,
    this.postalCode,
    this.whatsappNumber,
    this.createdAt,
    this.updatedAt,
    this.isBlacklisted = false,
  });

  factory InfluencerProfileModel.fromMap(Map<String, dynamic> data, String documentId) {
    return InfluencerProfileModel(
      uid: documentId,
      fullName: data['fullName'] ?? '',
      contentCategory: data['contentCategory'] ?? '',
      socialPlatform: data['socialPlatform'] ?? '',
      socialUsername: data['socialUsername'] ?? '',
      followers: data['followers'] ?? 0,
      engagementRate: (data['engagementRate'] ?? 0.0).toDouble(),
      priceRate: (data['priceRate'] ?? 0.0).toDouble(),
      portfolioUrl: data['portfolioUrl'],
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      bankName: data['bankName'],
      bankAccountNumber: data['bankAccountNumber'],
      bankAccountHolder: data['bankAccountHolder'],
      address: data['address'],
      postalCode: data['postalCode'],
      whatsappNumber: data['whatsappNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isBlacklisted: data['isBlacklisted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'contentCategory': contentCategory,
      'socialPlatform': socialPlatform,
      'socialUsername': socialUsername,
      'followers': followers,
      'engagementRate': engagementRate,
      'priceRate': priceRate,
      'portfolioUrl': portfolioUrl,
      'description': description,
      'photoUrl': photoUrl,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountHolder': bankAccountHolder,
      'address': address,
      'postalCode': postalCode,
      'whatsappNumber': whatsappNumber,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isBlacklisted': isBlacklisted,
    };
  }
}
