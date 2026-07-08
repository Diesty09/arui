import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Siapa Anda?',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih peran Anda untuk mulai menggunakan aplikasi',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              _buildRoleCard(
                context: context,
                title: 'Saya UMKM',
                description: 'Cari influencer untuk promosikan produk saya',
                icon: Icons.storefront,
                onTap: () => context.push('/login', extra: 'umkm'),
              ),
              
              const SizedBox(height: 24),
              
              _buildRoleCard(
                context: context,
                title: 'Saya Influencer',
                description: 'Temukan tawaran promosi dari UMKM',
                icon: Icons.campaign,
                onTap: () => context.push('/login', extra: 'influencer'),
              ),
              
              const Spacer(),
              
              TextButton(
                onPressed: () => context.push('/login', extra: 'admin'),
                child: const Text(
                  'Masuk sebagai Admin', 
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryLight, width: 2),
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primaryLight.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }
}
