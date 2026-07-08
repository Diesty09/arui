import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/influencer_profile_model.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/profile_avatar.dart';

final influencersProvider = StreamProvider.autoDispose<List<InfluencerProfileModel>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.getAllInfluencersStream();
});

class InfluencerListScreen extends ConsumerWidget {
  const InfluencerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final influencersAsync = ref.watch(influencersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Influencer'),
      ),
      body: influencersAsync.when(
        data: (influencers) {
          if (influencers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Belum ada influencer', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: influencers.length,
            itemBuilder: (context, index) {
              final influencer = influencers[index];
              return _buildInfluencerCard(context, influencer);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfluencerCard(BuildContext context, InfluencerProfileModel influencer) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          context.push('/umkm/influencers/profile', extra: influencer.uid);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                imageUrl: influencer.photoUrl,
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                fallbackIcon: Icons.person,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      influencer.fullName.isNotEmpty ? influencer.fullName : 'Tanpa Nama',
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${influencer.contentCategory} | ${influencer.socialPlatform}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          influencer.averageRating > 0 ? influencer.averageRating.toStringAsFixed(1) : 'Baru',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(NumberFormat.compact().format(influencer.followers)),
                        const SizedBox(width: 16),
                        Icon(Icons.monetization_on_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(formatCurrency.format(influencer.priceRate)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
