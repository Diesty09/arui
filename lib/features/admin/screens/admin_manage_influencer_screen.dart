import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/influencer_profile_model.dart';

class AdminManageInfluencerScreen extends StatelessWidget {
  const AdminManageInfluencerScreen({super.key});

  void _showDetailDialog(BuildContext context, InfluencerProfileModel inf) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final formatNumber = NumberFormat.compact(locale: 'id');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(inf.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rating chip
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${inf.averageRating.toStringAsFixed(1)} (${inf.totalReviews} ulasan)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow('Platform', '${inf.socialPlatform} @${inf.socialUsername}'),
              _detailRow('Kategori', inf.contentCategory),
              _detailRow('Followers', formatNumber.format(inf.followers)),
              _detailRow('Engagement Rate', '${inf.engagementRate.toStringAsFixed(1)}%'),
              _detailRow('Tarif', formatCurrency.format(inf.priceRate)),
              _detailRow('Deskripsi', inf.description),
              if (inf.bankName != null && inf.bankName!.isNotEmpty) ...[
                _detailRow('Bank', inf.bankName!),
                _detailRow('No. Rekening', inf.bankAccountNumber ?? '-'),
                _detailRow('Atas Nama', inf.bankAccountHolder ?? '-'),
              ],
              if (inf.address != null && inf.address!.isNotEmpty)
                _detailRow('Alamat', '${inf.address!}${inf.postalCode != null && inf.postalCode!.isNotEmpty ? ", Kodepos ${inf.postalCode}" : ""}'),
              if (inf.portfolioUrl != null && inf.portfolioUrl!.isNotEmpty)
                _detailRow('Portfolio', inf.portfolioUrl!),
              // Nomor WA — hanya ditampilkan di panel admin
              if (inf.whatsappNumber != null && inf.whatsappNumber!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('WhatsApp', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Hanya Admin', style: TextStyle(fontSize: 9, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Text(inf.whatsappNumber!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const Divider(height: 16),
                    ],
                  ),
                ),
              _detailRow('UID', inf.uid),

              if (inf.createdAt != null)
                _detailRow('Daftar', '${inf.createdAt!.day}/${inf.createdAt!.month}/${inf.createdAt!.year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value.isNotEmpty ? value : '-', style: const TextStyle(fontSize: 14)),
          const Divider(height: 16),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun Influencer?'),
        content: Text('Yakin ingin menghapus "$name"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('influencer_profiles')
                    .doc(uid)
                    .delete();
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Akun "$name" berhasil dihapus'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final formatNumber = NumberFormat.compact(locale: 'id');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data Influencer'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('influencer_profiles')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada data Influencer', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final inf = InfluencerProfileModel.fromMap(
                docs[index].data() as Map<String, dynamic>,
                docs[index].id,
              );

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: Text(
                      inf.fullName.isNotEmpty ? inf.fullName[0].toUpperCase() : 'I',
                      style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(inf.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${inf.socialPlatform} • ${formatNumber.format(inf.followers)} followers',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Row(
                        children: [
                          Text(
                            formatCurrency.format(inf.priceRate),
                            style: TextStyle(fontSize: 11, color: Colors.purple.shade600, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                          Text(
                            ' ${inf.averageRating.toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 11, color: Colors.amber.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.purple),
                        tooltip: 'Lihat Detail',
                        onPressed: () => _showDetailDialog(context, inf),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Hapus',
                        onPressed: () => _confirmDelete(context, inf.uid, inf.fullName),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
