import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campaign_model.dart';
import '../models/offer_model.dart';
import '../models/payment_model.dart';
import '../models/rating_model.dart';
import '../models/umkm_profile_model.dart';
import '../models/influencer_profile_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/blacklist_request_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- NOTIFICATIONS ---
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    final docRef = _firestore.collection('notifications').doc();
    final notification = NotificationModel(
      notificationId: docRef.id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    await docRef.set(notification.toMap());
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore.collection('notifications')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  // --- USER ---
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // --- UMKM PROFILE ---
  Future<void> saveUmkmProfile(UmkmProfileModel profile) async {
    await _firestore.collection('umkm_profiles').doc(profile.uid).set(profile.toMap());
  }

  Future<UmkmProfileModel?> getUmkmProfile(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('umkm_profiles').doc(uid).get();
    if (doc.exists) {
      return UmkmProfileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<UmkmProfileModel?> getUmkmProfileStream(String uid) {
    return _firestore.collection('umkm_profiles').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UmkmProfileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Stream<int> getUmkmCountStream() {
    return _firestore.collection('umkm_profiles').snapshots().map((snapshot) => snapshot.size);
  }

  // --- INFLUENCER PROFILE ---
  Future<void> saveInfluencerProfile(InfluencerProfileModel profile) async {
    final data = profile.toMap();
    data.remove('averageRating');
    data.remove('totalReviews');
    await _firestore.collection('influencer_profiles').doc(profile.uid).set(data, SetOptions(merge: true));
  }

  Future<InfluencerProfileModel?> getInfluencerProfile(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('influencer_profiles').doc(uid).get();
    if (doc.exists) {
      return InfluencerProfileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<InfluencerProfileModel?> getInfluencerProfileStream(String uid) {
    return _firestore.collection('influencer_profiles').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return InfluencerProfileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Stream<List<InfluencerProfileModel>> getAllInfluencersStream() {
    return _firestore.collection('influencer_profiles')
      .where('isBlacklisted', isNotEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => 
        InfluencerProfileModel.fromMap(doc.data(), doc.id)
      ).toList());
  }

  Stream<int> getInfluencerCountStream() {
    return _firestore.collection('influencer_profiles').snapshots().map((snapshot) => snapshot.size);
  }

  Future<List<String>> getAllInfluencerIds() async {
    final snapshot = await _firestore.collection('users')
        .where('role', isEqualTo: 'influencer')
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // --- CAMPAIGNS ---
  Future<void> createCampaign(CampaignModel campaign) async {
    DocumentReference docRef = _firestore.collection('campaigns').doc();
    CampaignModel newCampaign = CampaignModel(
      campaignId: docRef.id,
      umkmId: campaign.umkmId,
      umkmName: campaign.umkmName,
      title: campaign.title,
      productName: campaign.productName,
      productDescription: campaign.productDescription,
      promotionType: campaign.promotionType,
      targetMarket: campaign.targetMarket,
      platform: campaign.platform,
      budget: campaign.budget,
      duration: campaign.duration,
      deadline: campaign.deadline,
      productImageUrl: campaign.productImageUrl,
      status: campaign.status,
      createdAt: DateTime.now(),
    );
    await docRef.set(newCampaign.toMap());

    try {
      final influencerIds = await getAllInfluencerIds();
      for (final id in influencerIds) {
        await sendNotification(
          userId: id,
          title: 'Campaign Baru!',
          message: 'UMKM ${campaign.umkmName} mengunggah campaign baru: "${campaign.title}".',
          type: 'campaign_new',
        );
      }
    } catch (e) {
      print('Gagal mengirim notifikasi campaign baru: $e');
    }
  }

  Stream<List<CampaignModel>> getCampaignsStream() {
    return _firestore.collection('campaigns')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => 
        CampaignModel.fromMap(doc.data(), doc.id)
      ).toList());
  }

  Stream<int> getActiveCampaignCountStream() {
    return _firestore.collection('campaigns')
      .where('status', isEqualTo: 'aktif')
      .snapshots()
      .map((snapshot) => snapshot.size);
  }

  Stream<int> getUmkmActiveCampaignCountStream(String umkmId) {
    return _firestore.collection('campaigns')
      .where('umkmId', isEqualTo: umkmId)
      .where('status', isEqualTo: 'aktif')
      .snapshots()
      .map((snapshot) => snapshot.size);
  }

  Future<void> updateCampaignStatus(String campaignId, String status) async {
    await _firestore.collection('campaigns').doc(campaignId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCampaign(CampaignModel campaign) async {
    await _firestore.collection('campaigns').doc(campaign.campaignId).update(campaign.toMap());
  }

  Future<void> deleteCampaign(String campaignId) async {
    final batch = _firestore.batch();

    // Hapus campaign
    final campaignRef = _firestore.collection('campaigns').doc(campaignId);
    batch.delete(campaignRef);

    // Hapus semua offers terkait
    final offersSnapshot = await _firestore.collection('offers')
        .where('campaignId', isEqualTo: campaignId)
        .get();
    for (final doc in offersSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<Map<String, dynamic>?> getAppPaymentConfig() async {
    final doc = await _firestore.collection('app_config').doc('payment_methods').get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<void> saveAppPaymentConfig(Map<String, dynamic> config) async {
    await _firestore.collection('app_config').doc('payment_methods').set(config, SetOptions(merge: true));
  }

  Future<void> createOffer(OfferModel offer) async {
    DocumentReference docRef = _firestore.collection('offers').doc();
    OfferModel newOffer = OfferModel(
      offerId: docRef.id,
      campaignId: offer.campaignId,
      umkmId: offer.umkmId,
      influencerId: offer.influencerId,
      influencerName: offer.influencerName,
      offerDescription: offer.offerDescription,
      offerPrice: offer.offerPrice,
      estimatedDuration: offer.estimatedDuration,
      note: offer.note,
      createdAt: DateTime.now(),
      instagramUsername: offer.instagramUsername,
      instagramFollowers: offer.instagramFollowers,
      instagramLink: offer.instagramLink,
      instagramCategory: offer.instagramCategory,
      instagramEr: offer.instagramEr,
      tiktokUsername: offer.tiktokUsername,
      tiktokFollowers: offer.tiktokFollowers,
      tiktokLink: offer.tiktokLink,
      tiktokCategory: offer.tiktokCategory,
      tiktokEr: offer.tiktokEr,
      kolFullName: offer.kolFullName,
      kolAge: offer.kolAge,
      gender: offer.gender,
      domicile: offer.domicile,
      fullAddress: offer.fullAddress,
      phoneNumber: offer.phoneNumber,
      jobInfo: offer.jobInfo,
      handleBy: offer.handleBy,
      waMgNumber: offer.waMgNumber,
    );
    await docRef.set(newOffer.toMap());

    try {
      await sendNotification(
        userId: offer.umkmId,
        title: 'Penawaran Baru!',
        message: '${offer.influencerName} mengirim penawaran baru.',
        type: 'offer_status',
      );
    } catch (e) {
      print('Gagal mengirim notifikasi penawaran baru: $e');
    }
  }

  Stream<List<OfferModel>> getOffersForCampaign(String campaignId) {
    return _firestore.collection('offers')
      .where('campaignId', isEqualTo: campaignId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => 
        OfferModel.fromMap(doc.data(), doc.id)
      ).toList());
  }

  Future<void> updateOffer(OfferModel offer) async {
    await _firestore.collection('offers').doc(offer.offerId).update(offer.toMap());
  }

  Stream<int> getUmkmNewOfferCountStream(String umkmId) {
    return _firestore.collection('offers')
      .where('umkmId', isEqualTo: umkmId)
      .where('status', isEqualTo: 'menunggu')
      .snapshots()
      .map((snapshot) => snapshot.size);
  }

  // --- PAYMENTS ---
  Future<void> createPayment(PaymentModel payment) async {
    DocumentReference docRef = _firestore.collection('payments').doc();
    PaymentModel newPayment = PaymentModel(
      paymentId: docRef.id,
      campaignId: payment.campaignId,
      umkmId: payment.umkmId,
      influencerId: payment.influencerId,
      amount: payment.amount,
      method: payment.method,
      proofImageUrl: payment.proofImageUrl,
      createdAt: DateTime.now(),
    );
    await docRef.set(newPayment.toMap());
  }

  Future<void> createAndConfirmPayment(PaymentModel payment) async {
    final batch = _firestore.batch();

    DocumentReference paymentRef = _firestore.collection('payments').doc();
    PaymentModel newPayment = PaymentModel(
      paymentId: paymentRef.id,
      campaignId: payment.campaignId,
      umkmId: payment.umkmId,
      influencerId: payment.influencerId,
      amount: payment.amount,
      method: payment.method,
      proofImageUrl: payment.proofImageUrl,
      status: 'dikonfirmasi',
      createdAt: DateTime.now(),
      verifiedAt: DateTime.now(),
    );
    batch.set(paymentRef, newPayment.toMap());

    final campaignRef = _firestore.collection('campaigns').doc(payment.campaignId);
    final campaignDoc = await campaignRef.get();
    
    String campaignTitle = '';
    if (campaignDoc.exists) {
      campaignTitle = campaignDoc.data()?['title'] ?? '';
      final targetCount = campaignDoc.data()?['targetInfluencerCount'] ?? 1;

      final offersSnapshot = await _firestore.collection('offers')
        .where('campaignId', isEqualTo: payment.campaignId)
        .where('influencerId', isEqualTo: payment.influencerId)
        .limit(1)
        .get();
        
      if (offersSnapshot.docs.isNotEmpty) {
        batch.update(offersSnapshot.docs.first.reference, {'status': 'diterima'});
      }

      final acceptedOffers = await _firestore.collection('offers')
        .where('campaignId', isEqualTo: payment.campaignId)
        .where('status', isEqualTo: 'diterima')
        .get();
        
      final totalAccepted = acceptedOffers.docs.length + 1;
      
      if (totalAccepted >= targetCount) {
        batch.update(campaignRef, {'status': 'proses'});
      } else {
        batch.update(campaignRef, {'status': 'aktif'});
      }
    }

    await batch.commit();

    try {
      await sendNotification(
        userId: payment.influencerId,
        title: 'Penawaran Diterima!',
        message: 'Selamat! Penawaran Anda untuk campaign "$campaignTitle" telah diterima.',
        type: 'offer_status',
      );
    } catch (e) {
      print('Gagal mengirim notifikasi penerimaan offer: $e');
    }
  }

  Stream<int> getTotalTransactionsCountStream() {
    return _firestore.collection('payments').snapshots().map((snapshot) => snapshot.size);
  }

  Stream<List<PaymentModel>> getPaymentsForInfluencer(String influencerId) {
    return _firestore.collection('payments')
      .where('influencerId', isEqualTo: influencerId)
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });
  }

  Stream<List<PaymentModel>> getPaymentsForUmkm(String umkmId) {
    return _firestore.collection('payments')
      .where('umkmId', isEqualTo: umkmId)
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => PaymentModel.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });
  }


  Stream<List<OfferModel>> getOffersForInfluencer(String influencerId) {
    return _firestore.collection('offers')
      .where('influencerId', isEqualTo: influencerId)
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => OfferModel.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });
  }

  Stream<List<RatingModel>> getRatingsForInfluencer(String influencerId) {
    return _firestore.collection('ratings')
      .where('influencerId', isEqualTo: influencerId)
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => RatingModel.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });
  }

  // --- RATINGS ---
  Future<void> createRating(RatingModel rating) async {
    DocumentReference docRef = _firestore.collection('ratings').doc();
    RatingModel newRating = RatingModel(
      ratingId: docRef.id,
      campaignId: rating.campaignId,
      umkmId: rating.umkmId,
      influencerId: rating.influencerId,
      ratingValue: rating.ratingValue,
      reviewText: rating.reviewText,
      createdAt: DateTime.now(),
    );

    final influencerRef = _firestore.collection('influencer_profiles').doc(rating.influencerId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(influencerRef);
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final currentTotal = data['totalReviews'] ?? 0;
        final currentAvg = (data['averageRating'] ?? 0.0).toDouble();
        
        final newTotal = currentTotal + 1;
        final newAvg = ((currentAvg * currentTotal) + rating.ratingValue) / newTotal;
        
        transaction.update(influencerRef, {
          'totalReviews': newTotal,
          'averageRating': newAvg,
        });
      }
      transaction.set(docRef, newRating.toMap());
    });

    // Cari payment yang berhubungan dan ubah status klaimnya
    final paymentsSnapshot = await _firestore.collection('payments')
        .where('campaignId', isEqualTo: rating.campaignId)
        .where('influencerId', isEqualTo: rating.influencerId)
        .where('status', isEqualTo: 'dikonfirmasi')
        .get();

    for (var doc in paymentsSnapshot.docs) {
      await doc.reference.update({'claimStatus': 'bisa_diklaim'});
    }
  }

  Future<void> claimInfluencerFee(String paymentId) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'claimStatus': 'diklaim',
    });
  }

  // --- CHAT ---
  Future<String> createOrGetChat(String campaignId, String umkmId, String influencerId) async {
    final query = await _firestore.collection('chats')
        .where('campaignId', isEqualTo: campaignId)
        .where('umkmId', isEqualTo: umkmId)
        .where('influencerId', isEqualTo: influencerId)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    
    DocumentReference docRef = _firestore.collection('chats').doc();
    await docRef.set({
      'campaignId': campaignId,
      'umkmId': umkmId,
      'influencerId': influencerId,
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<String> getOrCreateChatRoom(String campaignId, String umkmId, String influencerId) async {
    final chatId = '${campaignId}_${umkmId}_$influencerId';
    
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (doc.exists) {
      return chatId;
    }

    String umkmName = 'UMKM';
    String influencerName = 'Influencer';

    try {
      final umkmDoc = await _firestore.collection('users').doc(umkmId).get();
      if (umkmDoc.exists) {
        umkmName = umkmDoc.data()?['name'] ?? 'UMKM';
      }
      final influencerDoc = await _firestore.collection('users').doc(influencerId).get();
      if (influencerDoc.exists) {
        influencerName = influencerDoc.data()?['name'] ?? 'Influencer';
      }
    } catch (e) {
      // ignore
    }

    await _firestore.collection('chats').doc(chatId).set({
      'campaignId': campaignId,
      'umkmId': umkmId,
      'influencerId': influencerId,
      'umkmName': umkmName,
      'influencerName': influencerName,
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    return chatId;
  }

  Stream<QuerySnapshot> getChatsForUser(String userId, String role) {
    if (role == 'admin') {
      return _firestore.collection('chats')
        .snapshots();
    }
    String field = role == 'umkm' ? 'umkmId' : 'influencerId';
    return _firestore.collection('chats')
      .where(field, isEqualTo: userId)
      .snapshots();
  }

  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  Future<void> sendMessage(String chatId, String senderId, String receiverId, String text) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // --- BLACKLIST REQUESTS ---
  Future<void> submitBlacklistRequest(BlacklistRequestModel request) async {
    DocumentReference docRef = _firestore.collection('blacklist_requests').doc();
    final newRequest = BlacklistRequestModel(
      id: docRef.id,
      umkmId: request.umkmId,
      umkmName: request.umkmName,
      influencerId: request.influencerId,
      influencerName: request.influencerName,
      influencerAccountName: request.influencerAccountName,
      reason: request.reason,
      proofImageUrl: request.proofImageUrl,
      status: request.status,
      createdAt: request.createdAt,
    );
    await docRef.set(newRequest.toMap());
  }

  Stream<List<BlacklistRequestModel>> getBlacklistRequestsStream() {
    return _firestore.collection('blacklist_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) =>
            BlacklistRequestModel.fromMap(doc.data(), doc.id)
        ).toList());
  }

  Future<void> updateBlacklistRequestStatus(String requestId, String status, String influencerId, {double fineAmount = 0.0}) async {
    final batch = _firestore.batch();
    
    final requestRef = _firestore.collection('blacklist_requests').doc(requestId);
    batch.update(requestRef, {
      'status': status,
      if (status == 'disetujui') 'fineAmount': fineAmount,
    });
    
    if (status == 'disetujui') {
      final influencerRef = _firestore.collection('influencer_profiles').doc(influencerId);
      batch.set(influencerRef, {'isBlacklisted': true}, SetOptions(merge: true));
    }
    
    await batch.commit();
  }

  Future<bool> canUmkmBlacklistInfluencer(String umkmId, String influencerId) async {
    final offerSnapshot = await _firestore.collection('offers')
        .where('umkmId', isEqualTo: umkmId)
        .where('influencerId', isEqualTo: influencerId)
        .where('status', isEqualTo: 'diterima')
        .get();
        
    if (offerSnapshot.docs.isEmpty) return false;

    for (var doc in offerSnapshot.docs) {
      final offer = OfferModel.fromMap(doc.data(), doc.id);
      final campaignDoc = await _firestore.collection('campaigns').doc(offer.campaignId).get();
      if (campaignDoc.exists) {
        final campaign = CampaignModel.fromMap(campaignDoc.data()!, campaignDoc.id);
        if (campaign.deadline.isBefore(DateTime.now())) {
          return true; // Missed deadline
        }
      }
    }

    final ratingSnapshot = await _firestore.collection('ratings')
        .where('umkmId', isEqualTo: umkmId)
        .where('influencerId', isEqualTo: influencerId)
        .where('ratingValue', isLessThanOrEqualTo: 3)
        .get();
        
    if (ratingSnapshot.docs.isNotEmpty) {
      return true; // Bad rating
    }

    return false;
  }

  Stream<BlacklistRequestModel?> getActiveBlacklistRequestForInfluencer(String influencerId) {
    return _firestore.collection('blacklist_requests')
        .where('influencerId', isEqualTo: influencerId)
        .where('status', isEqualTo: 'disetujui')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          // Sort manually since we can't chain orderBy easily with inequalities
          final docs = snapshot.docs.toList();
          docs.sort((a, b) {
            final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return BlacklistRequestModel.fromMap(docs.first.data(), docs.first.id);
        });
  }

  Future<void> submitBlacklistAppeal(String requestId, String statementUrl, String compensationUrl) async {
    await _firestore.collection('blacklist_requests').doc(requestId).update({
      'appealStatementUrl': statementUrl,
      'appealCompensationUrl': compensationUrl,
      'appealStatus': 'menunggu',
    });
  }

  Future<void> updateBlacklistAppealStatus(String requestId, String status, String influencerId) async {
    final batch = _firestore.batch();
    
    final requestRef = _firestore.collection('blacklist_requests').doc(requestId);
    batch.update(requestRef, {
      'appealStatus': status,
      if (status == 'disetujui') 'status': 'selesai',
    });
    
    if (status == 'disetujui') {
      final influencerRef = _firestore.collection('influencer_profiles').doc(influencerId);
      batch.set(influencerRef, {'isBlacklisted': false}, SetOptions(merge: true));
    }
    
    await batch.commit();
  }
}
