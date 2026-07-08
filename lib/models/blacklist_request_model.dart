import 'package:cloud_firestore/cloud_firestore.dart';

class BlacklistRequestModel {
  final String id;
  final String umkmId;
  final String umkmName;
  final String influencerId;
  final String influencerName;
  final String reason;
  final String influencerAccountName;
  final String? proofImageUrl;
  final String status; // 'menunggu', 'disetujui', 'ditolak', 'selesai'
  final double fineAmount;
  final String? appealStatementUrl;
  final String? appealCompensationUrl;
  final String appealStatus; // 'none', 'menunggu', 'disetujui', 'ditolak'
  final DateTime? createdAt;

  BlacklistRequestModel({
    required this.id,
    required this.umkmId,
    required this.umkmName,
    required this.influencerId,
    required this.influencerName,
    required this.reason,
    required this.influencerAccountName,
    this.proofImageUrl,
    required this.status,
    this.fineAmount = 0.0,
    this.appealStatementUrl,
    this.appealCompensationUrl,
    this.appealStatus = 'none',
    this.createdAt,
  });

  factory BlacklistRequestModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BlacklistRequestModel(
      id: documentId,
      umkmId: data['umkmId'] ?? '',
      umkmName: data['umkmName'] ?? '',
      influencerId: data['influencerId'] ?? '',
      influencerName: data['influencerName'] ?? '',
      influencerAccountName: data['influencerAccountName'] ?? '',
      reason: data['reason'] ?? '',
      proofImageUrl: data['proofImageUrl'],
      status: data['status'] ?? 'menunggu',
      fineAmount: (data['fineAmount'] ?? 0.0).toDouble(),
      appealStatementUrl: data['appealStatementUrl'],
      appealCompensationUrl: data['appealCompensationUrl'],
      appealStatus: data['appealStatus'] ?? 'none',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'umkmId': umkmId,
      'umkmName': umkmName,
      'influencerId': influencerId,
      'influencerName': influencerName,
      'influencerAccountName': influencerAccountName,
      'reason': reason,
      'proofImageUrl': proofImageUrl,
      'status': status,
      'fineAmount': fineAmount,
      'appealStatementUrl': appealStatementUrl,
      'appealCompensationUrl': appealCompensationUrl,
      'appealStatus': appealStatus,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
