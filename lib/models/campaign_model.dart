import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignModel {
  final String campaignId;
  final String umkmId;
  final String umkmName;
  final String title;
  final String productName;
  final String productDescription;
  final String promotionType;
  final String targetMarket;
  final String platform;
  final double budget;
  final String duration;
  final DateTime deadline;
  final String? productImageUrl;
  final String status; // 'aktif', 'proses', 'selesai', 'dibatalkan'
  final String? selectedInfluencerId;
  final int targetInfluencerCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CampaignModel({
    required this.campaignId,
    required this.umkmId,
    required this.umkmName,
    required this.title,
    required this.productName,
    required this.productDescription,
    required this.promotionType,
    required this.targetMarket,
    required this.platform,
    required this.budget,
    required this.duration,
    required this.deadline,
    this.productImageUrl,
    this.status = 'aktif',
    this.selectedInfluencerId,
    this.targetInfluencerCount = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory CampaignModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CampaignModel(
      campaignId: documentId,
      umkmId: data['umkmId'] ?? '',
      umkmName: data['umkmName'] ?? '',
      title: data['title'] ?? '',
      productName: data['productName'] ?? '',
      productDescription: data['productDescription'] ?? '',
      promotionType: data['promotionType'] ?? '',
      targetMarket: data['targetMarket'] ?? '',
      platform: data['platform'] ?? '',
      budget: (data['budget'] ?? 0.0).toDouble(),
      duration: data['duration'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      productImageUrl: data['productImageUrl'],
      status: data['status'] ?? 'aktif',
      selectedInfluencerId: data['selectedInfluencerId'],
      targetInfluencerCount: data['targetInfluencerCount'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'umkmId': umkmId,
      'umkmName': umkmName,
      'title': title,
      'productName': productName,
      'productDescription': productDescription,
      'promotionType': promotionType,
      'targetMarket': targetMarket,
      'platform': platform,
      'budget': budget,
      'duration': duration,
      'deadline': Timestamp.fromDate(deadline),
      'productImageUrl': productImageUrl,
      'status': status,
      'selectedInfluencerId': selectedInfluencerId,
      'targetInfluencerCount': targetInfluencerCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
