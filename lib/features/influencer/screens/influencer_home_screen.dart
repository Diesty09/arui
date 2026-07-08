import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/influencer_profile_model.dart';
import '../../../models/offer_model.dart';
import '../../../shared/widgets/profile_avatar.dart';

class InfluencerHomeScreen extends ConsumerWidget {
  const InfluencerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Influencer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/chat'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User tidak ditemukan'));
          
          return StreamBuilder<InfluencerProfileModel?>(
            stream: FirestoreService().getInfluencerProfileStream(user.uid),
            builder: (context, profileSnapshot) {
              final profile = profileSnapshot.data;
              final isBlacklisted = profile?.isBlacklisted ?? false;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBlacklisted) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red),
                                SizedBox(width: 8),
                                Expanded(child: Text('Akun Anda masuk dalam Daftar Hitam (Blacklist)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('Anda tidak dapat menerima tawaran baru. Silakan ajukan banding dan berikan kompensasi kepada UMKM untuk mencabut status ini.', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => context.push('/influencer/appeal'),
                              child: const Text('Ajukan Banding (Cabut Blacklist)'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user.name}!',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Siap berkolaborasi dengan brand lokal?',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/influencer/profile'),
                          child: ProfileAvatar(
                            imageUrl: profile?.photoUrl,
                            radius: 25,
                            backgroundColor: Colors.purple,
                            fallbackIcon: Icons.person,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                
                StreamBuilder<List<OfferModel>>(
                  stream: FirestoreService().getOffersForInfluencer(user.uid),
                  builder: (context, offersSnapshot) {
                    final offers = offersSnapshot.data ?? [];
                    final acceptedCount = offers.where((o) => o.status == 'diterima').length;
                    final pendingCount = offers.where((o) => o.status == 'menunggu').length;

                    return Row(
                      children: [
                        _buildDashboardCard(
                          context: context,
                          title: 'Offer Diterima',
                          value: acceptedCount.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                          onTap: () => context.push('/influencer/work-history'),
                        ),
                        const SizedBox(width: 16),
                        _buildDashboardCard(
                          context: context,
                          title: 'Offer Menunggu',
                          value: pendingCount.toString(),
                          icon: Icons.hourglass_bottom,
                          color: Colors.orange,
                          onTap: () => context.push('/influencer/work-history'),
                        ),
                      ],
                    );
                  }
                ),
                
                const SizedBox(height: 32),
                Text(
                  'Cari Peluang',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isBlacklisted ? null : () {
                      context.push('/influencer/browse');
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Cari Campaign Tersedia'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
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

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
