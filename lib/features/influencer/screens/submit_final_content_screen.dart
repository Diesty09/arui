import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/offer_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';
import '../../shared/widgets/custom_text_field.dart';

class SubmitFinalContentScreen extends ConsumerStatefulWidget {
  final OfferModel offer;

  const SubmitFinalContentScreen({super.key, required this.offer});

  @override
  ConsumerState<SubmitFinalContentScreen> createState() => _SubmitFinalContentScreenState();
}

class _SubmitFinalContentScreenState extends ConsumerState<SubmitFinalContentScreen> {
  final _contentLinkController = TextEditingController();
  File? _contentProofImage;
  File? _insightProofImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isContentProof) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isContentProof) {
          _contentProofImage = File(image.path);
        } else {
          _insightProofImage = File(image.path);
        }
      });
    }
  }

  void _submitFinalContent() async {
    if (_contentLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap masukkan link konten')));
      return;
    }
    if (_contentProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap unggah screenshot bukti tayang')));
      return;
    }
    if (_insightProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap unggah screenshot insight')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storageService = StorageService();
      
      String? contentProofUrl = await storageService.uploadContentImage(
        _contentProofImage!, widget.offer.offerId, 'content'
      );
      String? insightProofUrl = await storageService.uploadContentImage(
        _insightProofImage!, widget.offer.offerId, 'insight'
      );

      if (contentProofUrl == null || insightProofUrl == null) {
        throw Exception('Gagal mengunggah gambar bukti');
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
        status: 'selesai', // Status berubah menjadi selesai setelah final dikirim
        createdAt: widget.offer.createdAt,
        draftLink: widget.offer.draftLink,
        revisionNote: widget.offer.revisionNote,
        revisionCount: widget.offer.revisionCount,
        contentLink: _contentLinkController.text.trim(),
        contentProofUrl: contentProofUrl,
        insightProofUrl: insightProofUrl,
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
      
      await FirestoreService().sendNotification(
        userId: widget.offer.umkmId,
        title: 'Hasil Akhir Dikirim!',
        message: '${widget.offer.influencerName} telah menyelesaikan pekerjaannya. Silakan berikan rating.',
        type: 'content_final',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil kerja final berhasil dikirim!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim hasil akhir: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImageUploader(String label, File? imageFile, bool isContentProof) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(isContentProof),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Ketuk untuk unggah gambar', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kirim Hasil Akhir')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Draft Anda telah disetujui! Lengkapi form di bawah ini sebagai bukti penyelesaian pekerjaan Anda.',
                      style: TextStyle(color: Colors.green, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            CustomTextField(
              label: 'Link Postingan Konten',
              hint: 'Cth: https://www.instagram.com/p/...',
              controller: _contentLinkController,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            _buildImageUploader('Screenshot Bukti Tayang Konten', _contentProofImage, true),
            const SizedBox(height: 24),
            
            _buildImageUploader('Screenshot Insight / Statistik', _insightProofImage, false),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFinalContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kirim Hasil Kerja Final'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
