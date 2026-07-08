import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/offer_model.dart';
import '../../../services/firestore_service.dart';
import '../../shared/widgets/custom_text_field.dart';

class ReviewDraftScreen extends ConsumerStatefulWidget {
  final OfferModel offer;

  const ReviewDraftScreen({super.key, required this.offer});

  @override
  ConsumerState<ReviewDraftScreen> createState() => _ReviewDraftScreenState();
}

class _ReviewDraftScreenState extends ConsumerState<ReviewDraftScreen> {
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
        );
      }
    }
  }

  void _updateOfferStatus(String newStatus, {bool isRevision = false}) async {
    setState(() => _isLoading = true);

    try {
      int newRevisionCount = widget.offer.revisionCount;
      if (isRevision) {
        if (_noteController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Harap masukkan catatan revisi')),
          );
          setState(() => _isLoading = false);
          return;
        }
        newRevisionCount++;
      }

      final updatedOffer = OfferModel(
        offerId: widget.offer.offerId,
        campaignId: widget.offer.campaignId,
        umkmId: widget.offer.umkmId,
        influencerId: widget.offer.influencerId,
        influencerName: widget.offer.influencerName,
        offerDescription: widget.offer.offerDescription,
        offerPrice: widget.offer.offerPrice,
        estimatedDuration: widget.offer.estimatedDuration,
        note: widget.offer.note,
        status: newStatus,
        createdAt: widget.offer.createdAt,
        draftLink: widget.offer.draftLink,
        revisionNote: isRevision ? _noteController.text.trim() : widget.offer.revisionNote,
        revisionCount: newRevisionCount,
        contentLink: widget.offer.contentLink,
        contentProofUrl: widget.offer.contentProofUrl,
        insightProofUrl: widget.offer.insightProofUrl,
        instagramUsername: widget.offer.instagramUsername,
        instagramFollowers: widget.offer.instagramFollowers,
        instagramLink: widget.offer.instagramLink,
        instagramCategory: widget.offer.instagramCategory,
        instagramEr: widget.offer.instagramEr,
        tiktokUsername: widget.offer.tiktokUsername,
        tiktokFollowers: widget.offer.tiktokFollowers,
        tiktokLink: widget.offer.tiktokLink,
        tiktokCategory: widget.offer.tiktokCategory,
        tiktokEr: widget.offer.tiktokEr,
        kolFullName: widget.offer.kolFullName,
        kolAge: widget.offer.kolAge,
        gender: widget.offer.gender,
        domicile: widget.offer.domicile,
        fullAddress: widget.offer.fullAddress,
        phoneNumber: widget.offer.phoneNumber,
        jobInfo: widget.offer.jobInfo,
        handleBy: widget.offer.handleBy,
        waMgNumber: widget.offer.waMgNumber,
      );

      await FirestoreService().updateOffer(updatedOffer);

      String notifTitle = isRevision ? 'Draft Perlu Direvisi' : 'Draft Di-ACC!';
      String notifMsg = isRevision 
        ? 'UMKM meminta revisi pada draft Anda. Silakan cek catatan revisi.' 
        : 'UMKM telah menyetujui draft Anda. Silakan posting dan unggah hasil akhir!';

      await FirestoreService().sendNotification(
        userId: widget.offer.influencerId,
        title: notifTitle,
        message: notifMsg,
        type: 'content_draft_status',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isRevision ? 'Catatan revisi dikirim' : 'Draft berhasil disetujui')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canRevise = widget.offer.revisionCount < 3;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Draft Konten')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Draft dari:', style: Theme.of(context).textTheme.titleSmall),
            Text(widget.offer.influencerName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Link Draft Konten:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrl(widget.offer.draftLink),
                    child: Text(
                      widget.offer.draftLink,
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revisi ke: ${widget.offer.revisionCount} / 3',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: canRevise ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 32),

            const Divider(),
            const SizedBox(height: 16),
            
            Text('Aksi Review', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            
            if (canRevise) ...[
              CustomTextField(
                label: 'Catatan Revisi (Jika Ditolak)',
                hint: 'Masukkan bagian yang perlu diperbaiki influencer...',
                controller: _noteController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: const Text(
                  'Batas maksimal revisi (3x) telah tercapai. Anda harus menyetujui draft ini atau membatalkan penawaran.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                if (canRevise)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => _updateOfferStatus('draft_revisi', isRevision: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Minta Revisi'),
                    ),
                  )
                else 
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => _updateOfferStatus('ditolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Tolak Permanen'),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _updateOfferStatus('draft_acc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Setujui Draft'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
