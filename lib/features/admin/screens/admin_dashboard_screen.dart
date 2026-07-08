import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

final umkmCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirestoreService().getUmkmCountStream();
});

final influencerCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirestoreService().getInfluencerCountStream();
});

final activeCampaignCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirestoreService().getActiveCampaignCountStream();
});

final totalTransactionsCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirestoreService().getTotalTransactionsCountStream();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final umkmCount = ref.watch(umkmCountProvider).value ?? 0;
    final influencerCount = ref.watch(influencerCountProvider).value ?? 0;
    final activeCampaignCount = ref.watch(activeCampaignCountProvider).value ?? 0;
    final totalTransactionsCount = ref.watch(totalTransactionsCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.dashboard),
            ),
            const SizedBox(width: 8),
            const Text('Admin Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/role-selection');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan Sistem', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  context: context,
                  title: 'Total UMKM',
                  value: umkmCount.toString(),
                  color: Colors.blue,
                  onTap: () => context.push('/admin/umkm'),
                ),
                _buildStatCard(
                  context: context,
                  title: 'Total Influencer',
                  value: influencerCount.toString(),
                  color: Colors.purple,
                  onTap: () => context.push('/admin/influencers'),
                ),
                _buildStatCard(
                  context: context,
                  title: 'Campaign Aktif',
                  value: activeCampaignCount.toString(),
                  color: Colors.green,
                  onTap: () => context.push('/admin/campaigns'),
                ),
                _buildStatCard(
                  context: context,
                  title: 'Total Transaksi',
                  value: totalTransactionsCount.toString(),
                  color: Colors.orange,
                  onTap: () => context.push('/admin/payments'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            Text('Manajemen', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            _buildAdminMenuTile(
              context: context,
              title: 'Kelola Transaksi',
              icon: Icons.payment,
              color: Colors.orange,
              onTap: () => context.push('/admin/payments'),
            ),
            const SizedBox(height: 12),
            _buildAdminMenuTile(
              context: context,
              title: 'Konfigurasi Metode Bayar',
              icon: Icons.account_balance,
              color: Colors.indigo,
              onTap: () => context.push('/admin/payment-config'),
            ),
            const SizedBox(height: 12),
            _buildAdminMenuTile(
              context: context,
              title: 'Kelola Data UMKM',
              icon: Icons.store,
              color: Colors.blue,
              onTap: () => context.push('/admin/umkm'),
            ),
            const SizedBox(height: 12),
             _buildAdminMenuTile(
              context: context,
              title: 'Kelola Data Influencer',
              icon: Icons.person,
              color: Colors.purple,
              onTap: () => context.push('/admin/influencers'),
            ),
            const SizedBox(height: 12),
            _buildAdminMenuTile(
              context: context,
              title: 'Permintaan Blacklist',
              icon: Icons.report_problem,
              color: Colors.red.shade800,
              onTap: () => context.push('/admin/blacklist'),
            ),
            const SizedBox(height: 12),
            _buildAdminMenuTile(
              context: context,
              title: 'Pantau Chat UMKM & Influencer',
              icon: Icons.security_rounded,
              color: Colors.red,
              onTap: () => context.push('/chat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminMenuTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
