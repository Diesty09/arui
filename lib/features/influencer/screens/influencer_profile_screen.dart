import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/influencer_profile_model.dart';
import '../../../models/user_model.dart';
import '../../../models/blacklist_request_model.dart';
import '../../../shared/widgets/profile_avatar.dart';

class InfluencerProfileScreen extends ConsumerWidget {
  final String? influencerId;

  const InfluencerProfileScreen({super.key, this.influencerId});

  void _showBlacklistDialog(BuildContext context, String umkmId, String umkmName, String influencerId, String influencerName) {
    final accountController = TextEditingController();
    final reasonController = TextEditingController();
    bool isLoading = false;
    File? selectedImage;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Laporkan / Blacklist Influencer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Apakah Anda yakin ingin melaporkan influencer ini? Laporan Anda akan ditinjau oleh Admin.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Akun Influencer (IG/TikTok)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Alasan Blacklist',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  if (selectedImage != null)
                    Stack(
                      children: [
                        Image.file(selectedImage!, height: 100, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => selectedImage = null),
                          ),
                        ),
                      ],
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Bukti (Opsional)'),
                    onPressed: () async {
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => selectedImage = File(picked.path));
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isLoading ? null : () async {
                  if (reasonController.text.trim().isEmpty || accountController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan & Nama Akun wajib diisi')));
                    return;
                  }
                  setState(() => isLoading = true);
                  try {
                    String? proofUrl;
                    if (selectedImage != null) {
                      proofUrl = await StorageService().uploadProfileImage(selectedImage!, 'proof_${DateTime.now().millisecondsSinceEpoch}', 'blacklist');
                    }
                    final request = BlacklistRequestModel(
                      id: '',
                      umkmId: umkmId,
                      umkmName: umkmName,
                      influencerId: influencerId,
                      influencerName: influencerName,
                      influencerAccountName: accountController.text.trim(),
                      reason: reasonController.text.trim(),
                      proofImageUrl: proofUrl,
                      status: 'menunggu',
                    );
                    await FirestoreService().submitBlacklistRequest(request);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil dikirim ke Admin')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim laporan: $e')));
                    }
                  } finally {
                    if (context.mounted) setState(() => isLoading = false);
                  }
                },
                child: isLoading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kirim Laporan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnProfile = influencerId == null;
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        final targetUid = isOwnProfile ? (currentUser?.uid ?? '') : influencerId!;
        if (targetUid.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('User tidak ditemukan')),
          );
        }

        return FutureBuilder<UserModel?>(
          future: isOwnProfile 
              ? Future.value(currentUser) 
              : FirestoreService().getUserData(targetUid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            final user = userSnapshot.data;
            if (user == null) {
              return const Scaffold(
                body: Center(child: Text('User tidak ditemukan')),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Profil Influencer'),
                actions: isOwnProfile
                    ? [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => context.push('/influencer/profile/edit'),
                        ),
                      ]
                    : null,
              ),
              body: StreamBuilder<InfluencerProfileModel?>(
                stream: FirestoreService().getInfluencerProfileStream(targetUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final profile = snapshot.data;
                  final displayName = profile?.fullName ?? user.name;
                  
                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Center(
                        child: ProfileAvatar(
                          imageUrl: profile?.photoUrl,
                          radius: 50,
                          backgroundColor: Colors.purple,
                          fallbackIcon: Icons.person,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                      ),
                      Text(
                        user.email,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      
                      if (profile != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          elevation: 0,
                          color: Colors.purple.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.purple.withOpacity(0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem('Followers', NumberFormat.compact().format(profile.followers)),
                                    _buildStatItem('Rate', 'Rp ${NumberFormat.compact().format(profile.priceRate)}'),
                                    _buildRatingStatItem('Rating', profile.averageRating),
                                  ],
                                ),
                                const Divider(height: 32),
                                Text(
                                  profile.description.isEmpty ? 'Belum ada deskripsi' : profile.description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      if (isOwnProfile) ...[
                        _buildListTile(
                          icon: Icons.star,
                          title: 'Rating & Ulasan',
                          onTap: () => context.push('/influencer/ratings'),
                        ),
                        const Divider(),
                        _buildListTile(
                          icon: Icons.history,
                          title: 'Riwayat Pekerjaan',
                          onTap: () => context.push('/influencer/work-history'),
                        ),
                        const Divider(),
                        _buildListTile(
                          icon: Icons.payment,
                          title: 'Status Pembayaran',
                          onTap: () => context.push('/influencer/payments'),
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
                      ] else ...[
                        _buildListTile(
                          icon: Icons.star,
                          title: 'Rating & Ulasan',
                          onTap: () => context.push('/influencer/ratings', extra: targetUid),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text(
                              'Kirim Pesan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              if (currentUser == null) return;
                              try {
                                final chatId = await FirestoreService().getOrCreateChatRoom(
                                  'direct',
                                  currentUser.uid,
                                  targetUid,
                                );
                                if (context.mounted) {
                                  context.push('/chat/room', extra: {
                                    'chatId': chatId,
                                    'targetName': displayName,
                                    'campaignId': 'direct',
                                    'targetId': targetUid,
                                    'umkmId': currentUser.uid,
                                  });
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal memulai chat: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<bool>(
                          future: currentUser != null 
                              ? FirestoreService().canUmkmBlacklistInfluencer(currentUser.uid, targetUid)
                              : Future.value(false),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                            if (snapshot.data == true) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.report_problem, color: Colors.red),
                                  label: const Text(
                                    'Laporkan / Blacklist',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (currentUser == null) return;
                                    _showBlacklistDialog(
                                      context,
                                      currentUser.uid,
                                      currentUser.name,
                                      targetUid,
                                      displayName,
                                    );
                                  },
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
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

  Widget _buildRatingStatItem(String label, double rating) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.orange, size: 20),
            const SizedBox(width: 4),
            Text(rating > 0 ? rating.toStringAsFixed(1) : 'Baru', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
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
}
