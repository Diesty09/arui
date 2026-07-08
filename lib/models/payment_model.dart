import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String paymentId;
  final String campaignId;
  final String umkmId;
  final String influencerId;
  final double amount;
  final String method;
  final String? proofImageUrl;
  final String status; // 'menunggu', 'dikonfirmasi', 'ditolak'
  final String? adminNote;
  final String claimStatus; // 'none', 'bisa_diklaim', 'diklaim'
  final DateTime? createdAt;
  final DateTime? verifiedAt;

  PaymentModel({
    required this.paymentId,
    required this.campaignId,
    required this.umkmId,
    required this.influencerId,
    required this.amount,
    required this.method,
    this.proofImageUrl,
    this.status = 'menunggu',
    this.adminNote,
    this.claimStatus = 'none',
    this.createdAt,
    this.verifiedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PaymentModel(
      paymentId: documentId,
      campaignId: data['campaignId'] ?? '',
      umkmId: data['umkmId'] ?? '',
      influencerId: data['influencerId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      method: data['method'] ?? '',
      proofImageUrl: data['proofImageUrl'],
      status: data['status'] ?? 'menunggu',
      adminNote: data['adminNote'],
      claimStatus: data['claimStatus'] ?? 'none',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'umkmId': umkmId,
      'influencerId': influencerId,
      'amount': amount,
      'method': method,
      'proofImageUrl': proofImageUrl,
      'status': status,
      'adminNote': adminNote,
      'claimStatus': claimStatus,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
    };
  }
}
