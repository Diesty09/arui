import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/umkm_profile_model.dart';
import '../../../shared/widgets/profile_avatar.dart';

class UmkmHomeScreen extends ConsumerWidget {
  const UmkmHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda UMKM'),
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
          
          return RefreshIndicator(
            onRefresh: () async {
               // ref.refresh data
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              'Siap kembangkan bisnismu hari ini?',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<UmkmProfileModel?>(
                        stream: FirestoreService().getUmkmProfileStream(user.uid),
                        builder: (context, snapshot) {
                          final profile = snapshot.data;
                          return GestureDetector(
                            onTap: () => context.go('/umkm/profile'), // Assuming there's a profile route
                            child: ProfileAvatar(
                              imageUrl: profile?.logoUrl,
                              radius: 25,
                              backgroundColor: Colors.blue,
                              fallbackIcon: Icons.store,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Dashboard cards
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<int>(
                          stream: FirestoreService().getUmkmActiveCampaignCountStream(user.uid),
                          builder: (context, snapshot) {
                            return _buildDashboardCard(
                              context: context,
                              title: 'Campaign Aktif',
                              value: snapshot.data?.toString() ?? '0',
                              icon: Icons.campaign,
                              color: Colors.blue,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StreamBuilder<int>(
                          stream: FirestoreService().getUmkmNewOfferCountStream(user.uid),
                          builder: (context, snapshot) {
                            return _buildDashboardCard(
                              context: context,
                              title: 'Tawaran Baru',
                              value: snapshot.data?.toString() ?? '0',
                              icon: Icons.local_offer,
                              color: Colors.orange,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick actions
                  Text(
                    'Aksi Cepat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/umkm/campaigns/create');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Campaign Baru'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/umkm/influencers');
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Cari Influencer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
  }) {
    return Card(
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
      );
  }
}
