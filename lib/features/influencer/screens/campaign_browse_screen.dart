import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/campaign_model.dart';
import '../../../services/firestore_service.dart';

final allCampaignsProvider = StreamProvider.autoDispose<List<CampaignModel>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.getCampaignsStream().map((list) => 
    list.where((c) => c.status == 'aktif').toList()
  );
});

class CampaignBrowseScreen extends ConsumerWidget {
  const CampaignBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(allCampaignsProvider);
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Campaign'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama produk atau brand...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: campaignsAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return const Center(child: Text('Belum ada campaign aktif yang tersedia.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    context.push('/influencer/campaigns/detail', extra: campaign);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.store, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(campaign.umkmName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    campaign.title, 
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.money, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(formatCurrency.format(campaign.budget), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(label: Text(campaign.platform, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
                            Chip(label: Text(campaign.promotionType, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
