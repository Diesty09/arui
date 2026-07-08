import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../../models/campaign_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetMarketController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();
  final _targetInfluencerCountController = TextEditingController(text: '1');
  
  String _selectedPlatform = 'Instagram';
  String _selectedPromoType = 'Endorsement';
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  
  bool _isLoading = false;

  final List<String> _platforms = ['Instagram', 'TikTok', 'YouTube', 'Twitter/X'];
  final List<String> _promoTypes = [
    'Endorsement',
    'Review Produk',
    'Affiliate',
    'Brand Ambassador',
    'Ready to Post',
    'Review',
    'Buzzer'
  ];

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final user = await ref.read(currentUserProvider.future);
        if (user == null) throw Exception('User belum login');

        final campaign = CampaignModel(
          campaignId: '', // akan di-generate oleh firestore
          umkmId: user.uid,
          umkmName: user.name, // Idealnya ambil dari UmkmProfileModel
          title: _titleController.text,
          productName: _productNameController.text,
          productDescription: _descriptionController.text,
          promotionType: _selectedPromoType,
          targetMarket: _targetMarketController.text,
          platform: _selectedPlatform,
          budget: double.parse(_budgetController.text),
          duration: _durationController.text,
          deadline: _deadline,
          targetInfluencerCount: int.tryParse(_targetInfluencerCountController.text) ?? 1,
        );

        await ref.read(firestoreServiceProvider).createCampaign(campaign);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign berhasil dibuat!')),
        );
        context.pop(); // Kembali ke halaman sebelumnya
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Campaign Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Judul Campaign',
                hint: 'Cth: Endorse Sepatu Kets Lokal',
                controller: _titleController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Nama Produk',
                hint: 'Cth: Sepatu Arui',
                controller: _productNameController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Deskripsi Produk',
                hint: 'Jelaskan detail produk Anda',
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              
              Text('Platform Promosi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPlatform,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => _selectedPlatform = val!),
              ),
              
              const SizedBox(height: 16),
              
              Text('Jenis Promosi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPromoType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _promoTypes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => _selectedPromoType = val!),
              ),
              
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Target Pasar',
                hint: 'Cth: Remaja usia 15-25 tahun',
                controller: _targetMarketController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Budget (Rp)',
                hint: 'Cth: 500000',
                controller: _budgetController,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(val) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Durasi Kerja Sama',
                hint: 'Cth: 1 Bulan',
                controller: _durationController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Jumlah Influencer yang Dibutuhkan',
                hint: 'Cth: 3',
                controller: _targetInfluencerCountController,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(val) == null) return 'Harus berupa angka';
                  if (int.parse(val) < 1) return 'Minimal 1';
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              Text('Deadline Pengerjaan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('${_deadline.day}/${_deadline.month}/${_deadline.year}'),
                ),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buat Campaign'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
