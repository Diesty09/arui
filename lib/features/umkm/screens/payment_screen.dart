import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../models/payment_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

final appPaymentConfigProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  return FirestoreService().getAppPaymentConfig();
});

class PaymentScreen extends ConsumerStatefulWidget {
  final String campaignId;
  final String influencerId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.campaignId,
    required this.influencerId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  File? _proofImage;
  bool _isLoading = false;
  String _selectedMethod = 'transfer'; // 'transfer', 'ewallet', or 'qris'

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  void _submitPayment() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap upload bukti pembayaran')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User error');

      String dummyProofUrl = 'https://example.com/proof.jpg';

      double fee = widget.amount * 0.02;
      double totalToPay = widget.amount + fee;

      String methodString = 'Transfer Bank';
      if (_selectedMethod == 'ewallet') methodString = 'E-Wallet';
      if (_selectedMethod == 'qris') methodString = 'QRIS';

      final payment = PaymentModel(
        paymentId: '',
        campaignId: widget.campaignId,
        umkmId: user.uid,
        influencerId: widget.influencerId,
        amount: totalToPay,
        method: methodString,
        proofImageUrl: dummyProofUrl,
        status: 'menunggu',
      );

      await FirestoreService().createPayment(payment);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil dikirim! Menunggu konfirmasi admin.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal submit pembayaran: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double fee = widget.amount * 0.02;
    double totalToPay = widget.amount + fee;
    final configAsync = ref.watch(appPaymentConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total amount card
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Total Pembayaran', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${_formatNumber(totalToPay)}',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Harga Influencer: Rp ${_formatNumber(widget.amount)}  +  Biaya Layanan 2%: Rp ${_formatNumber(fee)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment method selector
            const Text('Pilih Kategori Pembayaran',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildMethodButton(
                  context,
                  id: 'transfer',
                  title: 'Transfer Bank',
                  icon: Icons.account_balance,
                  activeColor: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                _buildMethodButton(
                  context,
                  id: 'ewallet',
                  title: 'E-Wallet',
                  icon: Icons.account_balance_wallet,
                  activeColor: Colors.teal,
                ),
                const SizedBox(width: 8),
                _buildMethodButton(
                  context,
                  id: 'qris',
                  title: 'QRIS',
                  icon: Icons.qr_code_scanner,
                  activeColor: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Payment destination info from app config
            configAsync.when(
              data: (config) {
                List<dynamic> methods = [];
                if (config != null && config['methods'] != null) {
                  methods = config['methods'] as List<dynamic>;
                }

                if (methods.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Info pembayaran belum diatur oleh Admin. Hubungi admin platform.',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<dynamic> filteredMethods = [];
                if (_selectedMethod == 'transfer') {
                  filteredMethods = methods.where((m) => m['type'] == 'bank').toList();
                } else if (_selectedMethod == 'ewallet') {
                  filteredMethods = methods.where((m) => m['type'] == 'ewallet').toList();
                } else if (_selectedMethod == 'qris') {
                  filteredMethods = methods.where((m) => m['type'] == 'qris').toList();
                }

                if (filteredMethods.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Metode pembayaran ini belum tersedia.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return Column(
                  children: filteredMethods.map((method) {
                    if (method['type'] == 'bank') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTransferInfo(
                          method['providerName'] ?? '-',
                          method['accountNumber'] ?? '-',
                          method['accountHolder'] ?? '-',
                          context,
                        ),
                      );
                    } else if (method['type'] == 'ewallet') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildEwalletInfo(
                          method['providerName'] ?? '-',
                          method['accountNumber'] ?? '-',
                          method['accountHolder'] ?? '-',
                          context,
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildQrisInfo(
                          method['qrisImageBase64'],
                          method['note'] ?? 'Scan QR Code untuk membayar',
                        ),
                      );
                    }
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Gagal memuat info pembayaran: $e'),
            ),

            const SizedBox(height: 24),

            // Proof of payment
            const Text('Upload Bukti Pembayaran',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _proofImage != null
                      ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    width: _proofImage != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_proofImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Ketuk untuk upload bukti transfer/QRIS',
                            style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
                label: Text(_isLoading ? 'Memproses...' : 'Konfirmasi Pembayaran'),
                onPressed: _isLoading ? null : _submitPayment,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodButton(
    BuildContext context, {
    required String id,
    required String title,
    required IconData icon,
    required Color activeColor,
  }) {
    final isActive = _selectedMethod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeColor : Colors.grey.shade300,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? activeColor : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isActive ? activeColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferInfo(String bank, String number, String holder, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text('Transfer ke $bank',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text('No. Rekening', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ),
              Text(': ', style: TextStyle(color: Colors.grey.shade500)),
              Expanded(
                child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: number));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor disalin!'), duration: Duration(seconds: 2)),
                  );
                },
                child: Icon(Icons.copy, size: 18, color: Colors.blue.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('Atas Nama', holder),
        ],
      ),
    );
  }

  Widget _buildEwalletInfo(String name, String number, String holder, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.teal.shade700, size: 18),
              const SizedBox(width: 8),
              Text('Kirim ke $name',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text('Nomor HP', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ),
              Text(': ', style: TextStyle(color: Colors.grey.shade500)),
              Expanded(
                child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: number));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor disalin!'), duration: Duration(seconds: 2)),
                  );
                },
                child: Icon(Icons.copy, size: 18, color: Colors.teal.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('Atas Nama', holder),
        ],
      ),
    );
  }

  Widget _buildQrisInfo(String? imageBase64, String note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Text('QRIS Platform',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
            ],
          ),
          const SizedBox(height: 12),
          if (imageBase64 != null && imageBase64.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(imageBase64),
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('Format gambar tidak valid', style: TextStyle(color: Colors.orange.shade700))),
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 60, color: Colors.orange.shade400),
                  Text('QRIS', style: TextStyle(color: Colors.orange.shade700)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(note, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
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
      ],
    );
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
