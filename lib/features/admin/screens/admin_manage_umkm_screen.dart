import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/umkm_profile_model.dart';

class AdminManageUmkmScreen extends StatelessWidget {
  const AdminManageUmkmScreen({super.key});

  void _showDetailDialog(BuildContext context, UmkmProfileModel umkm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(umkm.businessName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Pemilik', umkm.ownerName),
              _detailRow('Kategori', umkm.category),
              _detailRow('Telepon', umkm.phone),
              _detailRow('Alamat', umkm.address),
              _detailRow('Deskripsi', umkm.description),
              _detailRow('UID', umkm.uid),
              if (umkm.createdAt != null)
                _detailRow('Daftar', '${umkm.createdAt!.day}/${umkm.createdAt!.month}/${umkm.createdAt!.year}'),
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
        title: const Text('Hapus Akun UMKM?'),
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
                // Hapus profil UMKM
                await FirebaseFirestore.instance
                    .collection('umkm_profiles')
                    .doc(uid)
                    .delete();
                // Hapus user dari collection users
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data UMKM'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('umkm_profiles')
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
                  Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada data UMKM', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final umkm = UmkmProfileModel.fromMap(
                docs[index].data() as Map<String, dynamic>,
                docs[index].id,
              );

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      umkm.businessName.isNotEmpty ? umkm.businessName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(umkm.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(umkm.ownerName, style: const TextStyle(fontSize: 12)),
                      Text(umkm.category,
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade600)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.blue),
                        tooltip: 'Lihat Detail',
                        onPressed: () => _showDetailDialog(context, umkm),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Hapus',
                        onPressed: () => _confirmDelete(context, umkm.uid, umkm.businessName),
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
