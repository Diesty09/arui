import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String offerId;
  final String campaignId;
  final String umkmId;
  final String influencerId;
  final String influencerName;
  final String offerDescription;
  final double offerPrice;
  final String estimatedDuration;
  final String note;
  final String status; // 'menunggu', 'diterima', 'ditolak', 'draft_dikirim', 'draft_revisi', 'draft_acc', 'selesai'
  final DateTime? createdAt;

  // Fields for Content Submission Workflow
  final String draftLink;
  final String revisionNote;
  final int revisionCount;
  final String contentLink;
  final String contentProofUrl;
  final String insightProofUrl;

  // Google Form Endorse Fields
  final String instagramUsername;
  final String instagramFollowers;
  final String instagramLink;
  final String instagramCategory;
  final String instagramEr;
  
  final String tiktokUsername;
  final String tiktokFollowers;
  final String tiktokLink;
  final String tiktokCategory;
  final String tiktokEr;

  final String kolFullName;
  final String kolAge;
  final String gender;
  final String domicile;
  final String fullAddress;
  final String phoneNumber;

  final String jobInfo;
  final String handleBy;
  final String waMgNumber;

  OfferModel({
    required this.offerId,
    required this.campaignId,
    required this.umkmId,
    required this.influencerId,
    required this.influencerName,
    required this.offerDescription,
    required this.offerPrice,
    required this.estimatedDuration,
    required this.note,
    this.status = 'menunggu',
    this.createdAt,
    this.draftLink = '',
    this.revisionNote = '',
    this.revisionCount = 0,
    this.contentLink = '',
    this.contentProofUrl = '',
    this.insightProofUrl = '',
    this.instagramUsername = '',
    this.instagramFollowers = '',
    this.instagramLink = '',
    this.instagramCategory = '',
    this.instagramEr = '',
    this.tiktokUsername = '',
    this.tiktokFollowers = '',
    this.tiktokLink = '',
    this.tiktokCategory = '',
    this.tiktokEr = '',
    this.kolFullName = '',
    this.kolAge = '',
    this.gender = '',
    this.domicile = '',
    this.fullAddress = '',
    this.phoneNumber = '',
    this.jobInfo = '',
    this.handleBy = '',
    this.waMgNumber = '',
  });

  factory OfferModel.fromMap(Map<String, dynamic> data, String documentId) {
    return OfferModel(
      offerId: documentId,
      campaignId: data['campaignId'] ?? '',
      umkmId: data['umkmId'] ?? '',
      influencerId: data['influencerId'] ?? '',
      influencerName: data['influencerName'] ?? '',
      offerDescription: data['offerDescription'] ?? '',
      offerPrice: (data['offerPrice'] ?? 0.0).toDouble(),
      estimatedDuration: data['estimatedDuration'] ?? '',
      note: data['note'] ?? '',
      status: data['status'] ?? 'menunggu',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      draftLink: data['draftLink'] ?? '',
      revisionNote: data['revisionNote'] ?? '',
      revisionCount: data['revisionCount'] ?? 0,
      contentLink: data['contentLink'] ?? '',
      contentProofUrl: data['contentProofUrl'] ?? '',
      insightProofUrl: data['insightProofUrl'] ?? '',
      instagramUsername: data['instagramUsername'] ?? '',
      instagramFollowers: data['instagramFollowers'] ?? '',
      instagramLink: data['instagramLink'] ?? '',
      instagramCategory: data['instagramCategory'] ?? '',
      instagramEr: data['instagramEr'] ?? '',
      tiktokUsername: data['tiktokUsername'] ?? '',
      tiktokFollowers: data['tiktokFollowers'] ?? '',
      tiktokLink: data['tiktokLink'] ?? '',
      tiktokCategory: data['tiktokCategory'] ?? '',
      tiktokEr: data['tiktokEr'] ?? '',
      kolFullName: data['kolFullName'] ?? '',
      kolAge: data['kolAge'] ?? '',
      gender: data['gender'] ?? '',
      domicile: data['domicile'] ?? '',
      fullAddress: data['fullAddress'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      jobInfo: data['jobInfo'] ?? '',
      handleBy: data['handleBy'] ?? '',
      waMgNumber: data['waMgNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'umkmId': umkmId,
      'influencerId': influencerId,
      'influencerName': influencerName,
      'offerDescription': offerDescription,
      'offerPrice': offerPrice,
      'estimatedDuration': estimatedDuration,
      'note': note,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'draftLink': draftLink,
      'revisionNote': revisionNote,
      'revisionCount': revisionCount,
      'contentLink': contentLink,
      'contentProofUrl': contentProofUrl,
      'insightProofUrl': insightProofUrl,
      'instagramUsername': instagramUsername,
      'instagramFollowers': instagramFollowers,
      'instagramLink': instagramLink,
      'instagramCategory': instagramCategory,
      'instagramEr': instagramEr,
      'tiktokUsername': tiktokUsername,
      'tiktokFollowers': tiktokFollowers,
      'tiktokLink': tiktokLink,
      'tiktokCategory': tiktokCategory,
      'tiktokEr': tiktokEr,
      'kolFullName': kolFullName,
      'kolAge': kolAge,
      'gender': gender,
      'domicile': domicile,
      'fullAddress': fullAddress,
      'phoneNumber': phoneNumber,
      'jobInfo': jobInfo,
      'handleBy': handleBy,
      'waMgNumber': waMgNumber,
    };
  }
}
