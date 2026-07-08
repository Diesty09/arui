import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/umkm_profile_model.dart';
import '../../../shared/widgets/profile_avatar.dart';

class UmkmProfileScreen extends ConsumerWidget {
  const UmkmProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/umkm/profile/edit'),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User tidak ditemukan'));
          return StreamBuilder<UmkmProfileModel?>(
            stream: FirestoreService().getUmkmProfileStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final profile = snapshot.data;
              final displayName = profile?.ownerName.isNotEmpty == true ? profile!.ownerName : user.name;
              
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Center(
                    child: ProfileAvatar(
                      imageUrl: profile?.logoUrl,
                      radius: 50,
                      backgroundColor: Colors.blue,
                      fallbackIcon: Icons.store,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                  ),
                  if (profile?.businessName.isNotEmpty == true)
                    Text(
                      profile!.businessName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                    ),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  if (profile != null && (profile.category.isNotEmpty || profile.description.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: Colors.blue.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (profile.category.isNotEmpty) ...[
                              _buildStatItem('Kategori', profile.category),
                              const Divider(height: 32),
                            ],
                            Text(
                              profile.description.isEmpty ? 'Belum ada deskripsi usaha' : profile.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),

              
              _buildListTile(
                icon: Icons.history,
                title: 'Riwayat Transaksi',
                onTap: () => context.push('/umkm/transactions'),
              ),
              const Divider(),
              _buildListTile(
                icon: Icons.settings,
                title: 'Pengaturan Akun',
                onTap: () => context.push('/umkm/settings'),
              ),
              const Divider(),
              _buildListTile(
                icon: Icons.help_outline,
                title: 'Bantuan & Dukungan',
                onTap: () => _showSupportDialog(context),
              ),
              const Divider(),
              _buildListTile(
                icon: Icons.logout,
                title: 'Keluar',
                color: Colors.red,
                onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/role-selection');
                },
              ),
                ],
              );
            }
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon, 
    required String title, 
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan gradien modern
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bantuan & Dukungan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ada kendala? Hubungi tim support kami.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Body dengan tombol-tombol kontak
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    _buildContactButton(
                      ctx: ctx,
                      icon: FontAwesomeIcons.whatsapp,
                      label: 'WhatsApp Support',
                      value: '0895-3350-38939',
                      color: const Color(0xFF25D366),
                      url: 'https://wa.me/62895335038939',
                    ),
                    const SizedBox(height: 12),
                    _buildContactButton(
                      ctx: ctx,
                      icon: FontAwesomeIcons.instagram,
                      label: 'Instagram Resmi',
                      value: '@diesty_arwid',
                      color: const Color(0xFFE1306C),
                      url: 'https://instagram.com/diesty_arwid',
                    ),
                    const SizedBox(height: 12),
                    _buildContactButton(
                      ctx: ctx,
                      icon: FontAwesomeIcons.tiktok,
                      label: 'TikTok Resmi',
                      value: '@diesty_arwid',
                      color: const Color(0xFF010101),
                      url: 'https://tiktok.com/@diesty_arwid',
                    ),
                    const SizedBox(height: 20),
                    
                    // Tombol Tutup
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade800,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
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

  Widget _buildContactButton({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String url,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Tidak bisa membuka $label')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon wrapper dengan background tipis sewarna brand
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FaIcon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Teks Detail
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Panah aksi kanan
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


