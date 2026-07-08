import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/campaign_model.dart';
import '../../../services/firestore_service.dart';

class AdminManageCampaignsScreen extends ConsumerStatefulWidget {
  const AdminManageCampaignsScreen({super.key});

  @override
  ConsumerState<AdminManageCampaignsScreen> createState() => _AdminManageCampaignsScreenState();
}

class _AdminManageCampaignsScreenState extends ConsumerState<AdminManageCampaignsScreen> {
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  void _confirmDelete(BuildContext context, CampaignModel campaign) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Campaign?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yakin ingin menghapus campaign:'),
            const SizedBox(height: 8),
            Text(
              '"${campaign.title}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Semua penawaran (offers) terkait campaign ini juga akan dihapus.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                await FirestoreService().deleteCampaign(campaign.campaignId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Campaign "${campaign.title}" berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
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

  void _showEditDialog(BuildContext context, CampaignModel campaign) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: campaign.title);
    final productNameController = TextEditingController(text: campaign.productName);
    final productDescriptionController = TextEditingController(text: campaign.productDescription);
    final budgetController = TextEditingController(text: campaign.budget.toInt().toString());
    final durationController = TextEditingController(text: campaign.duration);
    final targetMarketController = TextEditingController(text: campaign.targetMarket);
    
    String promotionType = campaign.promotionType;
    String platform = campaign.platform;
    String status = campaign.status;
    DateTime deadline = campaign.deadline;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Detail Campaign'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Judul Campaign'),
                        validator: (value) => value == null || value.isEmpty ? 'Judul wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: productNameController,
                        decoration: const InputDecoration(labelText: 'Nama Produk'),
                        validator: (value) => value == null || value.isEmpty ? 'Nama produk wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: productDescriptionController,
                        decoration: const InputDecoration(labelText: 'Deskripsi Produk'),
                        maxLines: 2,
                        validator: (value) => value == null || value.isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: platform,
                        decoration: const InputDecoration(labelText: 'Platform'),
                        items: ['Instagram', 'TikTok', 'YouTube', 'Lainnya']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) => setState(() => platform = val ?? platform),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: promotionType,
                        decoration: const InputDecoration(labelText: 'Tipe Promosi'),
                        items: ['Post/Feed', 'Story', 'Reels/Video Pendek', 'Review Produk', 'Lainnya']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) => setState(() => promotionType = val ?? promotionType),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: budgetController,
                        decoration: const InputDecoration(labelText: 'Budget (Rp)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Budget wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: durationController,
                        decoration: const InputDecoration(labelText: 'Durasi Pengerjaan'),
                        validator: (value) => value == null || value.isEmpty ? 'Durasi wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: targetMarketController,
                        decoration: const InputDecoration(labelText: 'Target Market'),
                        validator: (value) => value == null || value.isEmpty ? 'Target market wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status Campaign'),
                        items: ['aktif', 'proses', 'selesai', 'dibatalkan']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                            .toList(),
                        onChanged: (val) => setState(() => status = val ?? status),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Deadline:'),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: deadline,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                              );
                              if (picked != null) {
                                setState(() => deadline = picked);
                              }
                            },
                            child: Text(DateFormat('dd MMM yyyy').format(deadline)),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      final updatedCampaign = CampaignModel(
                        campaignId: campaign.campaignId,
                        umkmId: campaign.umkmId,
                        umkmName: campaign.umkmName,
                        title: titleController.text.trim(),
                        productName: productNameController.text.trim(),
                        productDescription: productDescriptionController.text.trim(),
                        promotionType: promotionType,
                        targetMarket: targetMarketController.text.trim(),
                        platform: platform,
                        budget: double.tryParse(budgetController.text) ?? campaign.budget,
                        duration: durationController.text.trim(),
                        deadline: deadline,
                        productImageUrl: campaign.productImageUrl,
                        status: status,
                        selectedInfluencerId: campaign.selectedInfluencerId,
                        targetInfluencerCount: campaign.targetInfluencerCount,
                        createdAt: campaign.createdAt,
                      );
                      
                      Navigator.pop(ctx);
                      try {
                        await FirestoreService().updateCampaign(updatedCampaign);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Campaign berhasil diperbarui!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal memperbarui: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Campaign Aktif'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('campaigns')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final campaigns = docs
              .map((doc) => CampaignModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .where((campaign) => campaign.status == 'aktif')
              .toList();

          if (campaigns.isEmpty) {
            return const Center(child: Text('Tidak ada campaign aktif.'));
          }

          return ListView.builder(
            itemCount: campaigns.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final campaign = campaigns[index];

              Color statusColor = Colors.green;
              if (campaign.status == 'proses') statusColor = Colors.orange;
              if (campaign.status == 'selesai') statusColor = Colors.blue;
              if (campaign.status == 'dibatalkan') statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              campaign.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Chip(
                            label: Text(
                              campaign.status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: statusColor.withOpacity(0.1),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UMKM: ${campaign.umkmName}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(Icons.money, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(formatCurrency.format(campaign.budget)),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(DateFormat('dd MMM yyyy').format(campaign.deadline)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            label: Text(campaign.platform, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(campaign.promotionType, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showEditDialog(context, campaign),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: () => _confirmDelete(context, campaign),
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
