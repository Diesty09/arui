import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String ratingId;
  final String campaignId;
  final String umkmId;
  final String influencerId;
  final int ratingValue; // 1 - 5
  final String reviewText;
  final DateTime? createdAt;

  RatingModel({
    required this.ratingId,
    required this.campaignId,
    required this.umkmId,
    required this.influencerId,
    required this.ratingValue,
    required this.reviewText,
    this.createdAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> data, String documentId) {
    return RatingModel(
      ratingId: documentId,
      campaignId: data['campaignId'] ?? '',
      umkmId: data['umkmId'] ?? '',
      influencerId: data['influencerId'] ?? '',
      ratingValue: data['ratingValue'] ?? 0,
      reviewText: data['reviewText'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'umkmId': umkmId,
      'influencerId': influencerId,
      'ratingValue': ratingValue,
      'reviewText': reviewText,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
