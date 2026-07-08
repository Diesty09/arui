import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/influencer_profile_model.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan & Diskusi'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User tidak ditemukan'));
          }

          final isAdmin = user.role == 'admin';

          return StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getChatsForUser(user.uid, user.role),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final chats = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
              chats.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = (aData['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
                final bTime = (bData['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
                return bTime.compareTo(aTime);
              });

              if (chats.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 72,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAdmin 
                              ? 'Tidak ada percakapan aktif di sistem.'
                              : 'Belum ada pesan.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAdmin
                              ? 'Seluruh percakapan yang dibuat oleh UMKM & Influencer akan muncul di sini.'
                              : 'Mulailah percakapan dari halaman detail penawaran campaign.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chatDoc = chats[index];
                  final chatData = chatDoc.data() as Map<String, dynamic>;
                  final chatId = chatDoc.id;

                  final lastMessage = chatData['lastMessage'] ?? '';
                  final lastMessageTime = (chatData['lastMessageTime'] as Timestamp?)?.toDate();

                  String titleName = 'Percakapan';
                  String subtitleDetail = '';

                  final umkmName = chatData['umkmName'] ?? 'UMKM';
                  final influencerName = chatData['influencerName'] ?? 'Influencer';

                  if (isAdmin) {
                    titleName = '$umkmName & $influencerName';
                    subtitleDetail = 'Monitoring Chat';
                  } else if (user.role == 'umkm') {
                    titleName = influencerName;
                    subtitleDetail = 'Influencer';
                  } else {
                    titleName = umkmName;
                    subtitleDetail = 'UMKM';
                  }

                  return Card(
                    elevation: 0.5,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: isAdmin
                            ? Colors.red.shade50
                            : Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          isAdmin ? Icons.security_rounded : Icons.person_rounded,
                          color: isAdmin ? Colors.red.shade600 : Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              titleName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            subtitleDetail,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMessage.isNotEmpty ? lastMessage : '(Belum ada pesan)',
                            style: TextStyle(
                              fontSize: 13,
                              color: lastMessage.isNotEmpty ? Colors.grey.shade700 : Colors.grey.shade400,
                              fontStyle: lastMessage.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastMessageTime != null)
                            Text(
                              DateFormat('HH:mm').format(lastMessageTime),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push('/chat/room', extra: {
                          'chatId': chatId,
                          'targetName': titleName,
                          'campaignId': chatData['campaignId'],
                          'targetId': user.role == 'umkm' ? chatData['influencerId'] : chatData['umkmId'],
                          'umkmId': chatData['umkmId'],
                        });
                      },
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: userAsync.when(
        data: (user) {
          if (user == null || user.role != 'umkm') return null;
          return FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return StreamBuilder<List<InfluencerProfileModel>>(
                    stream: FirestoreService().getAllInfluencersStream(),
                    builder: (context, influencerSnapshot) {
                      if (influencerSnapshot.hasError) {
                        return Center(child: Text('Error: ${influencerSnapshot.error}'));
                      }
                      if (influencerSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final influencers = influencerSnapshot.data ?? [];

                      if (influencers.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('Tidak ada influencer terdaftar.'),
                          ),
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Pilih Influencer untuk Chat',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: influencers.length,
                              itemBuilder: (context, index) {
                                final inf = influencers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: const Icon(Icons.person),
                                  ),
                                  title: Text(inf.fullName),
                                  subtitle: Text('@${inf.socialUsername} • ${inf.followers} Followers'),
                                  onTap: () async {
                                    Navigator.pop(context); // close bottom sheet
                                    try {
                                      final chatId = await FirestoreService().getOrCreateChatRoom(
                                        'direct_chat',
                                        user.uid,
                                        inf.uid,
                                      );
                                      if (context.mounted) {
                                        context.push('/chat/room', extra: {
                                          'chatId': chatId,
                                          'targetName': inf.fullName,
                                          'campaignId': 'direct_chat',
                                          'targetId': inf.uid,
                                          'umkmId': user.uid,
                                        });
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Gagal membuat chat: $e'),
                                            backgroundColor: Colors.red.shade700,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Mulai Chat'),
          );
        },
        loading: () => null,
        error: (e, st) => null,
      ),
    );
  }
}


