import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/offer_model.dart';
import '../../../services/firestore_service.dart';
import '../../shared/widgets/custom_text_field.dart';

class SubmitDraftScreen extends ConsumerStatefulWidget {
  final OfferModel offer;

  const SubmitDraftScreen({super.key, required this.offer});

  @override
  ConsumerState<SubmitDraftScreen> createState() => _SubmitDraftScreenState();
}

class _SubmitDraftScreenState extends ConsumerState<SubmitDraftScreen> {
  final _draftLinkController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _draftLinkController.text = widget.offer.draftLink;
  }

  @override
  void dispose() {
    _draftLinkController.dispose();
    super.dispose();
  }

  void _submitDraft() async {
    if (_draftLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan link draft konten')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
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
        status: 'draft_dikirim', // Update status
        createdAt: widget.offer.createdAt,
        draftLink: _draftLinkController.text.trim(),
        revisionNote: widget.offer.revisionNote,
        revisionCount: widget.offer.revisionCount,
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
      
      // Notifikasi ke UMKM
      await FirestoreService().sendNotification(
        userId: widget.offer.umkmId,
        title: 'Draft Konten Dikirim!',
        message: '${widget.offer.influencerName} telah mengirimkan draft konten untuk direview.',
        type: 'content_draft',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft berhasil dikirim ke UMKM')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim draft: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRevisi = widget.offer.status == 'draft_revisi';

    return Scaffold(
      appBar: AppBar(title: const Text('Kirim Draft Konten')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unggah draft konten Anda ke Google Drive / platform lain dan tempelkan link-nya di bawah ini.',
                      style: TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            
            if (isRevisi) ...[
              const SizedBox(height: 24),
              Text('Catatan Revisi dari UMKM:', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  widget.offer.revisionNote.isNotEmpty ? widget.offer.revisionNote : 'Tidak ada catatan.',
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sisa kesempatan revisi: ${3 - widget.offer.revisionCount}x',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],

            const SizedBox(height: 24),
            CustomTextField(
              label: 'Link Draft Konten',
              hint: 'Cth: https://drive.google.com/drive/folders/...',
              controller: _draftLinkController,
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitDraft,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kirim Draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
