import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/blacklist_request_model.dart';
import '../../../services/firestore_service.dart';

class AdminBlacklistScreen extends StatelessWidget {
  const AdminBlacklistScreen({super.key});

  void _showActionDialog(BuildContext context, BlacklistRequestModel request) {
    final fineController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Tinjau Laporan Blacklist'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pelapor: ${request.umkmName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Terlapor: ${request.influencerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Akun: ${request.influencerAccountName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Alasan:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(request.reason),
                  const SizedBox(height: 16),
                  if (request.proofImageUrl != null && request.proofImageUrl!.isNotEmpty) ...[
                    const Text('Bukti:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Image.network(request.proofImageUrl!, height: 150, fit: BoxFit.cover),
                    const SizedBox(height: 16),
                  ],
                  if (request.status == 'disetujui' && request.appealStatus == 'menunggu') ...[
                    const Divider(),
                    const Text('Pengajuan Banding (Pencabutan Blacklist)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),
                    if (request.appealStatementUrl != null)
                      TextButton.icon(
                        icon: const Icon(Icons.file_present),
                        label: const Text('Lihat Surat Pernyataan'),
                        onPressed: () { /* Show image logic */ },
                      ),
                    if (request.appealCompensationUrl != null)
                      TextButton.icon(
                        icon: const Icon(Icons.receipt),
                        label: const Text('Lihat Bukti Kompensasi'),
                        onPressed: () { /* Show image logic */ },
                      ),
                  ],
                  if (request.status == 'menunggu') ...[
                    const Divider(),
                    TextField(
                      controller: fineController,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Denda (Jika Disetujui)',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
              if (request.status == 'menunggu') ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isSubmitting ? null : () async {
                    setState(() => isSubmitting = true);
                    await _updateStatus(context, request, 'ditolak', 0);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Tolak'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: isSubmitting ? null : () async {
                    if (fineController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal denda wajib diisi jika disetujui')));
                      return;
                    }
                    final fineAmount = double.tryParse(fineController.text) ?? 0.0;
                    setState(() => isSubmitting = true);
                    await _updateStatus(context, request, 'disetujui', fineAmount);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Setujui'),
                ),
              ],
              if (request.status == 'disetujui' && request.appealStatus == 'menunggu') ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isSubmitting ? null : () async {
                    setState(() => isSubmitting = true);
                    await _updateAppealStatus(context, request, 'ditolak');
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Tolak Banding'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: isSubmitting ? null : () async {
                    setState(() => isSubmitting = true);
                    await _updateAppealStatus(context, request, 'disetujui');
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Setujui Banding'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, BlacklistRequestModel request, String status, double fineAmount) async {
    try {
      await FirestoreService().updateBlacklistRequestStatus(request.id, status, request.influencerId, fineAmount: fineAmount);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Laporan berhasil ${status == "disetujui" ? "disetujui" : "ditolak"}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
      }
    }
  }

  Future<void> _updateAppealStatus(BuildContext context, BlacklistRequestModel request, String status) async {
    try {
      await FirestoreService().updateBlacklistAppealStatus(request.id, status, request.influencerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banding berhasil ${status == "disetujui" ? "disetujui" : "ditolak"}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui banding: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan Blacklist'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BlacklistRequestModel>>(
        stream: FirestoreService().getBlacklistRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada laporan blacklist', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = requests[index];
              final dateStr = req.createdAt != null 
                  ? DateFormat('dd MMM yyyy, HH:mm').format(req.createdAt!)
                  : '-';

              Color statusColor = Colors.orange;
              if (req.status == 'disetujui') statusColor = Colors.green;
              if (req.status == 'ditolak') statusColor = Colors.red;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.report, color: Colors.white),
                  ),
                  title: Text('Laporkan: ${req.influencerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oleh: ${req.umkmName}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          requestStatusText(req),
                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showActionDialog(context, req),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String requestStatusText(BlacklistRequestModel req) {
    if (req.status == 'disetujui' && req.appealStatus == 'menunggu') return 'BANDING DITINJAU';
    if (req.status == 'selesai') return 'SELESAI (DICABUT)';
    return req.status.toUpperCase();
  }
}
