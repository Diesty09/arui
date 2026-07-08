import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/payment_model.dart';
import '../../../models/influencer_profile_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

final influencerPaymentsProvider = StreamProvider.autoDispose<List<PaymentModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return FirestoreService().getPaymentsForInfluencer(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

final influencerProfileForPaymentProvider = StreamProvider.autoDispose<InfluencerProfileModel?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return FirestoreService().getInfluencerProfileStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

class InfluencerPaymentScreen extends ConsumerWidget {
  const InfluencerPaymentScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'dikonfirmasi': return Colors.green;
      case 'ditolak': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'dikonfirmasi': return 'Dikonfirmasi';
      case 'ditolak': return 'Ditolak';
      default: return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(influencerPaymentsProvider);
    final profileAsync = ref.watch(influencerProfileForPaymentProvider);
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final formatDate = DateFormat('dd MMM yyyy', 'id_ID');

    final profile = profileAsync.value;
    final hasBankAccount = profile?.bankName != null && profile!.bankName!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Status Pembayaran')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bank account card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasBankAccount ? Colors.purple.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasBankAccount ? Colors.purple.shade200 : Colors.orange.shade200,
                ),
              ),
              child: hasBankAccount
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance, color: Colors.purple.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text('Akun Pembayaran Anda',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700, fontSize: 14)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => context.push('/influencer/profile/edit'),
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Edit', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildBankRow('Bank', profile.bankName!),
                        const SizedBox(height: 6),
                        _buildBankRow('No. Rekening',
                          profile.bankAccountNumber ?? '-',
                          copyable: true,
                          context: context,
                        ),
                        const SizedBox(height: 6),
                        _buildBankRow('Atas Nama', profile.bankAccountHolder ?? '-'),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Akun pembayaran belum diisi',
                                style: TextStyle(fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800)),
                              const SizedBox(height: 4),
                              Text('Tambahkan info rekening agar UMKM bisa transfer pembayaran',
                                style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/influencer/profile/edit'),
                          child: const Text('Isi Sekarang'),
                        ),
                      ],
                    ),
            ),

            // Payment history
            paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.payment_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Belum ada pembayaran',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Pembayaran akan muncul di sini setelah UMKM menerima penawaran Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  );
                }

                double totalDiterima = payments
                  .where((p) => p.status == 'dikonfirmasi' && (p.claimStatus == 'bisa_diklaim' || p.claimStatus == 'diklaim'))
                  .fold(0, (sum, p) => sum + p.amount);

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pendapatan Diterima',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(formatCurrency.format(totalDiterima),
                            style: const TextStyle(color: Colors.white,
                              fontSize: 26, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${payments.where((p) => p.status == 'dikonfirmasi').length} pembayaran sukses',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: _statusColor(payment.status).withOpacity(0.15),
                                  child: Icon(Icons.payments, color: _statusColor(payment.status)),
                                ),
                                title: Text(formatCurrency.format(payment.amount),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Via: ${payment.method}'),
                                    if (payment.createdAt != null)
                                      Text(formatDate.format(payment.createdAt!),
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    if (payment.status == 'dikonfirmasi' && payment.claimStatus == 'none') ...[
                                      const SizedBox(height: 4),
                                      Text('Menunggu UMKM menyelesaikan project & memberikan ulasan',
                                        style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontStyle: FontStyle.italic)),
                                    ],
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(payment.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _statusColor(payment.status).withOpacity(0.4)),
                                  ),
                                  child: Text(_statusLabel(payment.status),
                                    style: TextStyle(color: _statusColor(payment.status),
                                      fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              if (payment.status == 'dikonfirmasi' && (payment.claimStatus == 'bisa_diklaim' || payment.claimStatus == 'diklaim')) ...[
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (payment.claimStatus == 'bisa_diklaim')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                            minimumSize: const Size(0, 36),
                                          ),
                                          onPressed: () async {
                                            try {
                                              await FirestoreService().claimInfluencerFee(payment.paymentId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Fee berhasil diklaim!'), backgroundColor: Colors.green),
                                                );
                                              }
                                            } catch(e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Gagal klaim: $e'), backgroundColor: Colors.red),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Klaim Fee'),
                                        )
                                      else if (payment.claimStatus == 'diklaim')
                                        const Text('Fee Telah Diklaim', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankRow(String label, String value, {bool copyable = false, BuildContext? context}) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        Text(': ', style: TextStyle(color: Colors.grey.shade500)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        if (copyable && context != null)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nomor rekening disalin'), duration: Duration(seconds: 2)),
              );
            },
            child: Icon(Icons.copy, size: 16, color: Colors.purple.shade400),
          ),
      ],
    );
  }
}
