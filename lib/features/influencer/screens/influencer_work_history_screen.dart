import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../models/offer_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

final influencerOffersProvider = StreamProvider.autoDispose<List<OfferModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return FirestoreService().getOffersForInfluencer(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

class InfluencerWorkHistoryScreen extends ConsumerWidget {
  const InfluencerWorkHistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'diterima': 
      case 'draft_dikirim':
      case 'draft_revisi':
      case 'draft_acc':
      case 'selesai':
        return Colors.green;
      case 'ditolak': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'diterima': return 'Diterima ✓';
      case 'draft_dikirim': return 'Draft Dikirim';
      case 'draft_revisi': return 'Revisi Draft';
      case 'draft_acc': return 'Draft ACC';
      case 'selesai': return 'Selesai';
      case 'ditolak': return 'Ditolak';
      default: return 'Menunggu';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'diterima': return Icons.check_circle;
      case 'ditolak': return Icons.cancel;
      default: return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(influencerOffersProvider);
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final formatDate = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pekerjaan')),
      body: offersAsync.when(
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_history_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Belum ada riwayat pekerjaan', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Ajukan penawaran pada campaign UMKM untuk mulai bekerja',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }

          final accepted = offers.where((o) => o.status == 'diterima').length;
          final total = offers.length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Penawaran', total.toString(), Icons.send, Colors.blue),
                    Container(width: 1, height: 40, color: Colors.purple.shade200),
                    _buildSummaryItem('Diterima', accepted.toString(), Icons.check_circle, Colors.green),
                    Container(width: 1, height: 40, color: Colors.purple.shade200),
                    _buildSummaryItem('Menunggu', (total - accepted).toString(), Icons.hourglass_empty, Colors.orange),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(offer.offerDescription.isNotEmpty
                                    ? offer.offerDescription : 'Campaign ID: ${offer.campaignId.substring(0, 8)}...',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(offer.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _statusColor(offer.status).withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_statusIcon(offer.status), size: 12, color: _statusColor(offer.status)),
                                      const SizedBox(width: 4),
                                      Text(_statusLabel(offer.status),
                                        style: TextStyle(color: _statusColor(offer.status),
                                          fontWeight: FontWeight.bold, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (offer.note.isNotEmpty)
                              Text(offer.note, style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.monetization_on, size: 14, color: Colors.green.shade600),
                                const SizedBox(width: 4),
                                Text(formatCurrency.format(offer.offerPrice),
                                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(offer.estimatedDuration, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const Spacer(),
                                if (offer.createdAt != null)
                                  Text(formatDate.format(offer.createdAt!),
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                              ],
                            ),
                            
                            // Aksi Berdasarkan Status
                            if (offer.status == 'diterima' || offer.status == 'draft_revisi') ...[
                              const Divider(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/influencer/submit-draft', extra: offer),
                                  icon: const Icon(Icons.upload_file, size: 18),
                                  label: Text(offer.status == 'diterima' ? 'Kirim Draft Konten' : 'Kirim Revisi Draft'),
                                  style: ElevatedButton.styleFrom(backgroundColor: offer.status == 'draft_revisi' ? Colors.orange : Colors.green),
                                ),
                              ),
                            ] else if (offer.status == 'draft_dikirim') ...[
                              const Divider(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                child: const Center(child: Text('Menunggu UMKM mereview draft Anda', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12))),
                              ),
                            ] else if (offer.status == 'draft_acc') ...[
                              const Divider(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/influencer/submit-final', extra: offer),
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text('Kirim Hasil Kerja Final'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
