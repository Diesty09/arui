import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (mounted) context.go('/onboarding');
        return;
      }

      final userModel = await FirestoreService().getUserData(firebaseUser.uid)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      if (!mounted) return;

      if (userModel != null) {
        if (userModel.role == 'admin') {
          context.go('/admin/home');
        } else if (userModel.role == 'umkm') {
          context.go('/umkm/home');
        } else {
          context.go('/influencer/home');
        }
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              errorBuilder: (context, error, stackTrace) {
                // Fallback jika logo.png belum disimpan oleh user
                return Icon(
                  Icons.rocket_launch,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'ARUI Digital',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kolaborasi UMKM & Influencer',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }
}
