import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble;
      case 'offer_status':
        return Icons.local_offer;
      case 'campaign_new':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'chat':
        return Colors.blue;
      case 'offer_status':
        return Colors.green;
      case 'campaign_new':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final formatDate = DateFormat('dd MMM, HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          // Option to mark all as read or similar could go here
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User tidak ditemukan'));
          }

          return StreamBuilder<List<NotificationModel>>(
            stream: FirestoreService().getNotificationsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: Colors.purple.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Belum Ada Notifikasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Notifikasi tentang aktivitas campaign dan penawaran Anda akan muncul di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final iconColor = _getColorForType(notification.type);

                  return Container(
                    decoration: BoxDecoration(
                      color: notification.isRead ? Colors.transparent : Colors.purple.shade50.withOpacity(0.3),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        if (!notification.isRead) {
                          FirestoreService().markNotificationAsRead(notification.notificationId);
                        }
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForType(notification.type),
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.createdAt != null
                                ? formatDate.format(notification.createdAt!)
                                : '',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}
