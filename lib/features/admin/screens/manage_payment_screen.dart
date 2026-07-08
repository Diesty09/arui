import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManagePaymentScreen extends ConsumerWidget {
  const ManagePaymentScreen({super.key});

  void _verifyPayment(BuildContext context, String paymentId, Map<String, dynamic> data, bool isVerified) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final paymentRef = FirebaseFirestore.instance.collection('payments').doc(paymentId);
      batch.update(paymentRef, {
        'status': isVerified ? 'dikonfirmasi' : 'ditolak',
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      
      if (isVerified) {
        final campaignRef = FirebaseFirestore.instance.collection('campaigns').doc(data['campaignId']);
        final campaignDoc = await campaignRef.get();
        
        if (campaignDoc.exists) {
          final targetCount = campaignDoc.data()?['targetInfluencerCount'] ?? 1;
          
          // Update offer status
          final offersSnapshot = await FirebaseFirestore.instance.collection('offers')
            .where('campaignId', isEqualTo: data['campaignId'])
            .where('influencerId', isEqualTo: data['influencerId'])
            .limit(1)
            .get();
            
          if (offersSnapshot.docs.isNotEmpty) {
            batch.update(offersSnapshot.docs.first.reference, {
              'status': 'diterima',
            });
          }
          
          // Check total accepted (we add 1 because the current offer is being accepted in this batch)
          final acceptedOffers = await FirebaseFirestore.instance.collection('offers')
            .where('campaignId', isEqualTo: data['campaignId'])
            .where('status', isEqualTo: 'diterima')
            .get();
            
          final totalAccepted = acceptedOffers.docs.length + 1;
          
          if (totalAccepted >= targetCount) {
            batch.update(campaignRef, {'status': 'proses'});
          } else {
            batch.update(campaignRef, {'status': 'aktif'});
          }
        }
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isVerified ? 'Pembayaran Dikonfirmasi & Campaign Aktif' : 'Pembayaran Ditolak')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _confirmDeletePayment(BuildContext context, String paymentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat dibatalkan.'),
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
                await FirebaseFirestore.instance.collection('payments').doc(paymentId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus transaksi: $e'),
                      backgroundColor: Colors.red,
                    ),
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

  void _showEditPaymentDialog(BuildContext context, String paymentId, Map<String, dynamic> data) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: (data['amount'] ?? 0).toString());
    final methodController = TextEditingController(text: data['method'] ?? '');
    String status = data['status'] ?? 'menunggu';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Detail Transaksi'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Nominal wajib diisi' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: methodController,
                      decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                      validator: (value) => value == null || value.isEmpty ? 'Metode wajib diisi' : null,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status Transaksi'),
                      items: ['menunggu', 'dikonfirmasi', 'ditolak']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                          .toList(),
                      onChanged: (val) => setState(() => status = val ?? status),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      try {
                        await FirebaseFirestore.instance.collection('payments').doc(paymentId).update({
                          'amount': double.tryParse(amountController.text) ?? (data['amount'] ?? 0.0),
                          'method': methodController.text.trim(),
                          'status': status,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaksi berhasil diperbarui!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal memperbarui transaksi: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Transaksi')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final payments = snapshot.data?.docs ?? [];
          
          if (payments.isEmpty) return const Center(child: Text('Tidak ada data pembayaran.'));

          return ListView.builder(
            itemCount: payments.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = payments[index].data() as Map<String, dynamic>;
              final paymentId = payments[index].id;
              final status = data['status'] ?? 'menunggu';
              
              Color statusColor = Colors.orange;
              if (status == 'dikonfirmasi') statusColor = Colors.green;
              if (status == 'ditolak') statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ID: ${paymentId.substring(0, 8)}...', style: const TextStyle(color: Colors.grey)),
                          Chip(
                            label: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: statusColor.withOpacity(0.1),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('UMKM ID: ${data['umkmId'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        formatCurrency.format(data['amount'] ?? 0),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
                      ),
                      Text('Metode: ${data['method'] ?? '-'}'),
                      
                      if (status == 'menunggu') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _verifyPayment(context, paymentId, data, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _verifyPayment(context, paymentId, data, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Konfirmasi'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showEditPaymentDialog(context, paymentId, data),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _confirmDeletePayment(context, paymentId),
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            label: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12)),
                            style: TextButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
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
