import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../../models/influencer_profile_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

class EditInfluencerProfileScreen extends ConsumerStatefulWidget {
  const EditInfluencerProfileScreen({super.key});

  @override
  ConsumerState<EditInfluencerProfileScreen> createState() => _EditInfluencerProfileScreenState();
}

class _EditInfluencerProfileScreenState extends ConsumerState<EditInfluencerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _contentCategoryController = TextEditingController();
  final _socialPlatformController = TextEditingController();
  final _socialUsernameController = TextEditingController();
  final _followersController = TextEditingController();
  final _priceRateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _portfolioUrlController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _whatsappController = TextEditingController();
  
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  InfluencerProfileModel? _existingProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null) {
      final profile = await FirestoreService().getInfluencerProfile(user.uid);
      if (profile != null) {
        _existingProfile = profile;
        setState(() {
          _fullNameController.text = profile.fullName;
          _contentCategoryController.text = profile.contentCategory;
          _socialPlatformController.text = profile.socialPlatform;
          _socialUsernameController.text = profile.socialUsername;
          _followersController.text = profile.followers.toString();
          _priceRateController.text = profile.priceRate.toString();
          _descriptionController.text = profile.description;
          _portfolioUrlController.text = profile.portfolioUrl ?? '';
          _bankNameController.text = profile.bankName ?? '';
          _bankAccountNumberController.text = profile.bankAccountNumber ?? '';
          _bankAccountHolderController.text = profile.bankAccountHolder ?? '';
          _addressController.text = profile.address ?? '';
          _postalCodeController.text = profile.postalCode ?? '';
          _whatsappController.text = profile.whatsappNumber ?? '';
        });
      } else {
        setState(() {
          _fullNameController.text = user.name;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final user = await ref.read(currentUserProvider.future);
        if (user == null) throw Exception('User tidak valid');

        String? photoUrl = _existingProfile?.photoUrl;
        
        if (_imageFile != null) {
          try {
            final bytes = await _imageFile!.readAsBytes();
            final base64String = base64Encode(bytes);
            photoUrl = 'data:image/jpeg;base64,$base64String';
          } catch (e) {
            throw Exception('Gagal memproses gambar lokal.');
          }
        }

        final profile = InfluencerProfileModel(
          uid: user.uid,
          fullName: _fullNameController.text,
          contentCategory: _contentCategoryController.text,
          socialPlatform: _socialPlatformController.text,
          socialUsername: _socialUsernameController.text,
          followers: int.tryParse(_followersController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          priceRate: double.tryParse(_priceRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
          description: _descriptionController.text,
          portfolioUrl: _portfolioUrlController.text,
          engagementRate: _existingProfile?.engagementRate ?? 0.0,
          photoUrl: photoUrl,
          averageRating: _existingProfile?.averageRating ?? 0.0,
          totalReviews: _existingProfile?.totalReviews ?? 0,
          bankName: _bankNameController.text.isEmpty ? null : _bankNameController.text,
          bankAccountNumber: _bankAccountNumberController.text.isEmpty ? null : _bankAccountNumberController.text,
          bankAccountHolder: _bankAccountHolderController.text.isEmpty ? null : _bankAccountHolderController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          postalCode: _postalCodeController.text.isEmpty ? null : _postalCodeController.text,
          whatsappNumber: _whatsappController.text.isEmpty ? null : _whatsappController.text,
          createdAt: _existingProfile?.createdAt,
        );

        await FirestoreService().saveInfluencerProfile(profile);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan!')),
        );
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil Influencer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    _imageFile != null
                        ? CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            backgroundImage: FileImage(_imageFile!),
                          )
                        : ProfileAvatar(
                            imageUrl: _existingProfile?.photoUrl,
                            radius: 50,
                            backgroundColor: Colors.purple,
                            fallbackIcon: Icons.person,
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Nama Lengkap / Stage Name',
                hint: 'Masukkan nama Anda',
                controller: _fullNameController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Kategori Konten',
                hint: 'Cth: Beauty, Tech, Food',
                controller: _contentCategoryController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Platform Utama',
                hint: 'Cth: Instagram, TikTok',
                controller: _socialPlatformController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Username / Handle',
                hint: 'Cth: @aruicreator',
                controller: _socialUsernameController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Jumlah Followers',
                hint: 'Cth: 15000',
                controller: _followersController,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  final cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                  if (int.tryParse(cleanVal) == null) return 'Harus angka';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Tarif Dasar / Rate Card (Rp)',
                hint: 'Cth: 500000',
                controller: _priceRateController,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Wajib diisi';
                  final cleanVal = val.replaceAll(RegExp(r'[^0-9.]'), '');
                  if (double.tryParse(cleanVal) == null) return 'Harus angka';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Bio / Deskripsi Singkat',
                hint: 'Ceritakan tentang audiens dan konten Anda',
                controller: _descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Link Portofolio (Opsional)',
                hint: 'Link Google Drive / Website',
                controller: _portfolioUrlController,
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text('Akun Pembayaran', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              )),
              const SizedBox(height: 4),
              Text('Informasi rekening untuk menerima pembayaran dari UMKM',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Nama Bank',
                hint: 'Cth: BCA, BRI, Mandiri, GoPay, OVO',
                controller: _bankNameController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Nomor Rekening / Nomor HP',
                hint: 'Cth: 1234567890',
                controller: _bankAccountNumberController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Nama Pemilik Rekening',
                hint: 'Sesuai nama di buku tabungan',
                controller: _bankAccountHolderController,
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text('Alamat Lengkap', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              )),
              const SizedBox(height: 4),
              Text('Diperlukan untuk keperluan administrasi platform',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Alamat Lengkap',
                hint: 'Jl. Contoh No. 1, Kel. Contoh, Kec. Contoh, Kota',
                controller: _addressController,
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Kode Pos',
                hint: 'Cth: 12345',
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Kode pos wajib diisi' : null,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text('Kontak WhatsApp', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  )),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, size: 14, color: Colors.orange.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nomor WA hanya dapat dilihat oleh Admin platform. Tidak akan ditampilkan kepada pengguna lain.',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nomor WhatsApp',
                hint: 'Cth: 08123456789',
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Nomor WA wajib diisi' : null,
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Profil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
