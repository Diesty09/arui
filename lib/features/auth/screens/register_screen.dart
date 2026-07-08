import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Extra fields for UMKM
  final _businessNameController = TextEditingController();
  final _categoryController = TextEditingController();
  
  // Extra fields for Influencer
  final _platformController = TextEditingController();
  
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = ref.read(authServiceProvider);
        final user = await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          widget.role,
          _phoneController.text.trim(),
          widget.role == 'umkm' 
            ? {
                'businessName': _businessNameController.text.trim(),
                'category': _categoryController.text.trim(),
              }
            : {
                'platform': _platformController.text.trim(),
              },
        );

        if (user != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi berhasil!')),
          );
          
          if (user.role == 'umkm') {
             context.go('/umkm/home');
          } else {
             context.go('/influencer/home');
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftar: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String roleDisplay = widget.role == 'umkm' ? 'UMKM' : 'Influencer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).scaffoldBackgroundColor,
                      BlendMode.multiply,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 80),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Buat Akun Baru',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daftar sebagai $roleDisplay untuk memulai',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                
                CustomTextField(
                  label: widget.role == 'umkm' ? 'Nama Pemilik' : 'Nama / Stage Name',
                  hint: 'Masukkan nama Anda',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Nama wajib diisi';
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                if (widget.role == 'umkm') ...[
                  CustomTextField(
                    label: 'Nama Usaha / Toko',
                    hint: 'Masukkan nama usaha Anda',
                    controller: _businessNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Nama usaha wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Kategori Usaha',
                    hint: 'Cth: F&B, Fashion, Jasa',
                    controller: _categoryController,
                  ),
                  const SizedBox(height: 16),
                ],

                if (widget.role == 'influencer') ...[
                  CustomTextField(
                    label: 'Platform Utama',
                    hint: 'Cth: Instagram, TikTok, YouTube',
                    controller: _platformController,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Platform wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                CustomTextField(
                  label: 'Email',
                  hint: 'Masukkan email Anda',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email wajib diisi';
                    if (!value.endsWith('@gmail.com')) return 'Wajib menggunakan email Gmail asli (contoh: user@gmail.com)';
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Nomor HP',
                  hint: 'Contoh: 08123456789',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Nomor HP wajib diisi';
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Password',
                  hint: 'Minimal 6 karakter',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password wajib diisi';
                    if (value.length < 6) return 'Password minimal 6 karakter';
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Password harus mengandung huruf besar (A-Z)';
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return 'Password harus mengandung huruf kecil (a-z)';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Password harus mengandung angka (0-9)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Daftar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
