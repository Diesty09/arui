import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../../services/firestore_service.dart';
import '../../shared/widgets/custom_text_field.dart';

class AdminPaymentConfigScreen extends ConsumerStatefulWidget {
  const AdminPaymentConfigScreen({super.key});

  @override
  ConsumerState<AdminPaymentConfigScreen> createState() => _AdminPaymentConfigScreenState();
}

class _AdminPaymentConfigScreenState extends ConsumerState<AdminPaymentConfigScreen> {
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = false;
  bool _dataLoaded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() async {
    try {
      final config = await FirestoreService().getAppPaymentConfig();
      if (config != null && config['methods'] != null) {
        setState(() {
          _paymentMethods = List<Map<String, dynamic>>.from(config['methods']);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data. Error: $e')),
        );
      }
    } finally {
      setState(() => _dataLoaded = true);
    }
  }

  void _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await FirestoreService().saveAppPaymentConfig({'methods': _paymentMethods});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metode pembayaran berhasil disimpan!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Gagal Menyimpan'),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup'))
          ]
        )
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddMethodDialog([Map<String, dynamic>? existingMethod, int? index]) {
    String type = existingMethod?['type'] ?? 'bank';
    final providerNameController = TextEditingController(text: existingMethod?['providerName'] ?? '');
    final accountNumberController = TextEditingController(text: existingMethod?['accountNumber'] ?? '');
    final accountHolderController = TextEditingController(text: existingMethod?['accountHolder'] ?? '');
    final noteController = TextEditingController(text: existingMethod?['note'] ?? '');
    String qrisImageBase64 = existingMethod?['qrisImageBase64'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingMethod == null ? 'Tambah Metode Pembayaran' : 'Edit Metode Pembayaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipe Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'bank', child: Text('Transfer Bank')),
                        DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
                        DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    
                    if (type == 'bank' || type == 'ewallet') ...[
                      CustomTextField(
                        label: type == 'bank' ? 'Nama Bank' : 'Nama E-Wallet',
                        hint: type == 'bank' ? 'Cth: BCA, Mandiri' : 'Cth: GoPay, OVO',
                        controller: providerNameController,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: type == 'bank' ? 'Nomor Rekening' : 'Nomor HP',
                        hint: type == 'bank' ? '1234567890' : '081234567890',
                        controller: accountNumberController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Atas Nama',
                        hint: 'ARUI Digital',
                        controller: accountHolderController,
                      ),
                    ] else ...[
                      const Text('Upload QRIS (Gambar)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery, 
                            imageQuality: 50,
                            maxWidth: 500,
                            maxHeight: 500,
                          );
                          if (pickedFile != null) {
                            final bytes = await File(pickedFile.path).readAsBytes();
                            setDialogState(() {
                              qrisImageBase64 = base64Encode(bytes);
                            });
                          }
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          child: qrisImageBase64.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(base64Decode(qrisImageBase64), fit: BoxFit.contain),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Ketuk untuk pilih gambar QRIS', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Catatan Singkat (Opsional)',
                        hint: 'Scan untuk membayar',
                        controller: noteController,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (type == 'qris' && qrisImageBase64.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gambar QRIS wajib diupload!')),
                      );
                      return;
                    }
                    
                    final methodData = {
                      'id': existingMethod?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      'type': type,
                      'providerName': providerNameController.text,
                      'accountNumber': accountNumberController.text,
                      'accountHolder': accountHolderController.text,
                      'qrisImageBase64': qrisImageBase64,
                      'note': noteController.text,
                    };

                    setState(() {
                      if (index != null) {
                        _paymentMethods[index] = methodData;
                      } else {
                        _paymentMethods.add(methodData);
                      }
                    });
                    
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Sementara'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteMethod(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Metode?'),
        content: const Text('Yakin ingin menghapus metode pembayaran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _paymentMethods.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Konfigurasi Pembayaran')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMethodDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Metode'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.cloud_upload),
              label: Text(_isSaving ? 'Menyimpan ke Database...' : 'Simpan Perubahan ke Database'),
              onPressed: _isSaving ? null : _saveConfig,
            ),
          ),
        ),
      ),
      body: _paymentMethods.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belum ada metode pembayaran', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _paymentMethods.length,
            itemBuilder: (context, index) {
              final method = _paymentMethods[index];
              final type = method['type'];
              
              IconData icon;
              Color color;
              String title;
              String subtitle;

              if (type == 'bank') {
                icon = Icons.account_balance;
                color = Colors.blue;
                title = 'Bank ${method['providerName']}';
                subtitle = '${method['accountNumber']} a.n ${method['accountHolder']}';
              } else if (type == 'ewallet') {
                icon = Icons.account_balance_wallet;
                color = Colors.teal;
                title = 'E-Wallet ${method['providerName']}';
                subtitle = '${method['accountNumber']} a.n ${method['accountHolder']}';
              } else {
                icon = Icons.qr_code_scanner;
                color = Colors.orange;
                title = 'QRIS';
                subtitle = method['note'].toString().isNotEmpty ? method['note'] : 'QR Code Pembayaran';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color.withOpacity(0.5)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddMethodDialog(method, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMethod(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
