import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/blacklist_request_model.dart';

class InfluencerAppealScreen extends ConsumerStatefulWidget {
  const InfluencerAppealScreen({super.key});

  @override
  ConsumerState<InfluencerAppealScreen> createState() => _InfluencerAppealScreenState();
}

class _InfluencerAppealScreenState extends ConsumerState<InfluencerAppealScreen> {
  File? statementImage;
  File? compensationImage;
  bool isSubmitting = false;

  Future<void> _pickImage(bool isStatement) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isStatement) {
          statementImage = File(picked.path);
        } else {
          compensationImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _submitAppeal(String requestId) async {
    if (statementImage == null || compensationImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap unggah kedua bukti tersebut')));
      return;
    }
    setState(() => isSubmitting = true);
    try {
      final storage = StorageService();
      final statementUrl = await storage.uploadProfileImage(statementImage!, 'stmt_${DateTime.now().millisecondsSinceEpoch}', 'appeals');
      final compensationUrl = await storage.uploadProfileImage(compensationImage!, 'comp_${DateTime.now().millisecondsSinceEpoch}', 'appeals');
      
      await FirestoreService().submitBlacklistAppeal(requestId, statementUrl ?? '', compensationUrl ?? '');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banding berhasil diajukan, menunggu tinjauan Admin')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Banding')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User tidak ditemukan'));
          
          return StreamBuilder<BlacklistRequestModel?>(
            stream: FirestoreService().getActiveBlacklistRequestForInfluencer(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final request = snapshot.data;
              if (request == null) {
                return const Center(child: Text('Tidak ada blacklist aktif'));
              }

              if (request.appealStatus == 'menunggu') {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
                        SizedBox(height: 16),
                        Text('Banding Sedang Ditinjau', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Mohon tunggu admin meninjau pengajuan pencabutan blacklist Anda.', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              final formattedFine = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(request.fineAmount);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi Blacklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                          const SizedBox(height: 8),
                          Text('Dilaporkan oleh: ${request.umkmName}'),
                          const SizedBox(height: 4),
                          Text('Alasan: ${request.reason}'),
                          const Divider(),
                          const Text('Denda yang harus dibayar:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(formattedFine, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Untuk mencabut status blacklist, Anda wajib:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('1. Mengunggah Surat Pernyataan (ditandatangani) bahwa tidak akan mengulangi kesalahan.'),
                    const Text('2. Mengunggah Bukti Transfer Denda/Kompensasi.'),
                    const SizedBox(height: 24),
                    
                    const Text('1. Surat Pernyataan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildImagePicker(true),
                    
                    const SizedBox(height: 24),
                    const Text('2. Bukti Transfer Denda', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildImagePicker(false),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: isSubmitting ? null : () => _submitAppeal(request.id),
                        child: isSubmitting 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Kirim Pengajuan Banding', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildImagePicker(bool isStatement) {
    final image = isStatement ? statementImage : compensationImage;
    return InkWell(
      onTap: () => _pickImage(isStatement),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image, fit: BoxFit.cover),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Tap untuk unggah gambar', style: TextStyle(color: Colors.grey)),
                ],
              ),
      ),
    );
  }
}
