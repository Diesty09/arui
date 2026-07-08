import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role; // 'umkm' or 'influencer'

  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'admin') {
      _emailController.text = 'aruidigitalkreatif@gmail.com';
      _passwordController.text = 'AruiAdMiN03';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = ref.read(authServiceProvider);
        UserModel? user;
        try {
          user = await authService.signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );
          
          if (user == null && _emailController.text.trim() == 'aruidigitalkreatif@gmail.com' && widget.role == 'admin') {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              user = UserModel(
                uid: currentUser.uid,
                role: 'admin',
                name: 'Administrator',
                email: currentUser.email ?? '',
                phone: null,
                createdAt: DateTime.now(),
              );
              await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set(user.toMap());
            }
          }
          
          if (user == null) {
             throw Exception('Data user tidak ditemukan di database.');
          }
        } catch (e) {
          // Auto-register admin jika belum ada
          if (_emailController.text.trim() == 'aruidigitalkreatif@gmail.com' && widget.role == 'admin' && e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
            user = await authService.registerWithEmailAndPassword(
              _emailController.text.trim(),
              _passwordController.text,
              'Administrator',
              'admin',
              null,
              null,
            );
          } else {
            rethrow;
          }
        }

        if (user != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login berhasil!')),
          );
          
          if (user.role == 'admin') {
             context.go('/admin/home');
          } else if (user.role == 'umkm') {
             context.go('/umkm/home');
          } else {
             context.go('/influencer/home');
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal login: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailCont = TextEditingController(text: _emailController.text);
    final dialogFormKey = GlobalKey<FormState>();
    bool dialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Reset Password'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Masukkan email akun Anda. Kami akan mengirimkan link untuk mereset password Anda.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailCont,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Cth: user@example.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email wajib diisi';
                        if (!value.endsWith('@gmail.com')) return 'Wajib menggunakan email Gmail asli (contoh: user@gmail.com)';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          if (dialogFormKey.currentState!.validate()) {
                            setDialogState(() => dialogLoading = true);
                            try {
                              await ref.read(authServiceProvider).resetPassword(emailCont.text.trim());
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Link reset password berhasil dikirim ke email Anda!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal mengirim email reset: ${e.toString()}'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            } finally {
                              setDialogState(() => dialogLoading = false);
                            }
                          }
                        },
                  child: dialogLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Kirim Link'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => emailCont.dispose());
  }

  @override
  Widget build(BuildContext context) {
    String roleDisplay = widget.role == 'admin' ? 'Admin' : (widget.role == 'umkm' ? 'UMKM' : 'Influencer');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
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
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 100),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Selamat Datang Kembali!',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk sebagai $roleDisplay untuk melanjutkan',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                
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
                  label: 'Password',
                  hint: 'Masukkan password Anda',
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
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text('Lupa Password?'),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Masuk'),
                ),
                
                const SizedBox(height: 24),
                
                if (widget.role != 'admin')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun?'),
                      TextButton(
                        onPressed: () => context.push('/register', extra: widget.role),
                        child: const Text('Daftar di sini'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
