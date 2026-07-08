import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/campaign_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

final campaignsProvider = StreamProvider.autoDispose<List<CampaignModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  final firestoreService = FirestoreService();
  
  if (user == null) return const Stream.empty();
  
  return firestoreService.getCampaignsStream().map((list) => 
    list.where((c) => c.umkmId == user.uid).toList()
  );
});

class CampaignListScreen extends ConsumerStatefulWidget {
  const CampaignListScreen({super.key});

  @override
  ConsumerState<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends ConsumerState<CampaignListScreen> {


  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(campaignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/umkm/campaigns/create'),
          ),
        ],
      ),
      body: campaignsAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Belum ada campaign', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/umkm/campaigns/create'),
                    child: const Text('Buat Campaign Pertama'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return _buildCampaignCard(context, campaign);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, CampaignModel campaign) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    
    Color statusColor;
    switch(campaign.status) {
      case 'aktif': statusColor = Colors.green; break;
      case 'proses': statusColor = Colors.orange; break;
      case 'selesai': statusColor = Colors.blue; break;
      default: statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/umkm/campaigns/detail', extra: campaign),
        borderRadius: BorderRadius.circular(16),
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
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      campaign.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(campaign.platform, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(campaign.promotionType, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
