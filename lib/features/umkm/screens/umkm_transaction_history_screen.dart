import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/payment_model.dart';

class UmkmTransactionHistoryScreen extends ConsumerWidget {
  const UmkmTransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User tidak ditemukan'));

          return StreamBuilder<List<PaymentModel>>(
            stream: FirestoreService().getPaymentsForUmkm(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final payments = snapshot.data ?? [];

              if (payments.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada riwayat transaksi', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final payment = payments[index];

                  Color statusColor;
                  IconData statusIcon;
                  switch (payment.status) {
                    case 'dikonfirmasi':
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                      break;
                    case 'ditolak':
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel;
                      break;
                    default:
                      statusColor = Colors.orange;
                      statusIcon = Icons.access_time;
                  }

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                payment.method,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Row(
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    payment.status.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Text(
                            formatCurrency.format(payment.amount),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (payment.createdAt != null)
                            Text(
                              'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt!)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          Text(
                            'ID: ${payment.paymentId.substring(0, 8).toUpperCase()}...',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
