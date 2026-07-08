import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../../models/umkm_profile_model.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

class EditUmkmProfileScreen extends ConsumerStatefulWidget {
  const EditUmkmProfileScreen({super.key});

  @override
  ConsumerState<EditUmkmProfileScreen> createState() => _EditUmkmProfileScreenState();
}

class _EditUmkmProfileScreenState extends ConsumerState<EditUmkmProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  UmkmProfileModel? _existingProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null) {
      final profile = await FirestoreService().getUmkmProfile(user.uid);
      if (profile != null) {
        _existingProfile = profile;
        setState(() {
          _businessNameController.text = profile.businessName;
          _ownerNameController.text = profile.ownerName;
          _categoryController.text = profile.category;
          _addressController.text = profile.address;
          _descriptionController.text = profile.description;
          _phoneController.text = profile.phone;
        });
      } else {
        setState(() {
          _ownerNameController.text = user.name;
          _phoneController.text = user.phone ?? '';
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

        String? logoUrl = _existingProfile?.logoUrl;
        
        if (_imageFile != null) {
          try {
            final bytes = await _imageFile!.readAsBytes();
            final base64String = base64Encode(bytes);
            logoUrl = 'data:image/jpeg;base64,$base64String';
          } catch (e) {
            throw Exception('Gagal memproses gambar lokal.');
          }
        }

        final profile = UmkmProfileModel(
          uid: user.uid,
          businessName: _businessNameController.text,
          ownerName: _ownerNameController.text,
          category: _categoryController.text,
          address: _addressController.text,
          description: _descriptionController.text,
          phone: _phoneController.text,
          logoUrl: logoUrl,
          createdAt: _existingProfile?.createdAt,
        );

        await FirestoreService().saveUmkmProfile(profile);
        
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
      appBar: AppBar(title: const Text('Edit Profil UMKM')),
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
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            backgroundImage: FileImage(_imageFile!),
                          )
                        : ProfileAvatar(
                            imageUrl: _existingProfile?.logoUrl,
                            radius: 50,
                            backgroundColor: Colors.blue,
                            fallbackIcon: Icons.store,
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
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
                label: 'Nama Usaha / Toko',
                hint: 'Masukkan nama usaha',
                controller: _businessNameController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Nama Pemilik',
                hint: 'Masukkan nama pemilik',
                controller: _ownerNameController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Kategori Usaha',
                hint: 'Cth: F&B, Fashion, Jasa',
                controller: _categoryController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Alamat',
                hint: 'Alamat lengkap usaha',
                controller: _addressController,
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Deskripsi Singkat',
                hint: 'Ceritakan tentang usaha Anda',
                controller: _descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Nomor Telepon/WhatsApp',
                hint: 'Nomor yang bisa dihubungi',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
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
