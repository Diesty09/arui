import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';

class UmkmAccountSettingsScreen extends ConsumerWidget {
  const UmkmAccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Akun')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User tidak ditemukan'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info akun
              Card(
                elevation: 0,
                color: Colors.blue.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informasi Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      _infoRow(Icons.person_outline, 'Nama', user.name),
                      _infoRow(Icons.email_outlined, 'Email', user.email),
                      _infoRow(Icons.badge_outlined, 'Peran', 'UMKM'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text('Kelola Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),

              _buildSettingTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profil Bisnis',
                subtitle: 'Ubah nama usaha, kategori, alamat',
                color: Colors.blue,
                onTap: () => context.push('/umkm/profile/edit'),
              ),
              const SizedBox(height: 8),
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: 'Ubah Password',
                subtitle: 'Ganti password akun Anda',
                color: Colors.orange,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Ubah Password'),
                      content: const Text(
                        'Untuk mengubah password, silakan logout dan gunakan fitur "Lupa Password" pada halaman login.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Mengerti'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              const Text('Lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),

              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                subtitle: 'ARUI DIGITAL 1.0.0',
                color: Colors.grey,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'ARUI DIGITAL',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '©2026 | @aruidigitalkreatif | Diesty | All right reserved',
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildSettingTile(
                icon: Icons.logout,
                title: 'Keluar',
                subtitle: 'Logout dari akun ini',
                color: Colors.red,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Konfirmasi Logout'),
                      content: const Text('Yakin ingin keluar dari akun?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/role-selection');
                  }
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
