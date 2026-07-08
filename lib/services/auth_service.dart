import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan stream user yang sedang login
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mendapatkan data user saat ini dari Firestore
  Future<UserModel?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    }
    return null;
  }

  // Registrasi
  Future<UserModel?> registerWithEmailAndPassword(
    String email, 
    String password, 
    String name, 
    String role, 
    String? phone,
    Map<String, dynamic>? extraData,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          role: role,
          name: name,
          email: email,
          phone: phone,
          createdAt: DateTime.now(),
        );

        // Simpan data user ke Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // Otomatis buat profil awal berdasarkan role
        if (extraData != null) {
          if (role == 'umkm') {
            await _firestore.collection('umkm_profiles').doc(user.uid).set({
              'uid': user.uid,
              'businessName': extraData['businessName'] ?? '',
              'ownerName': name,
              'category': extraData['category'] ?? '',
              'address': '',
              'description': '',
              'phone': phone ?? '',
            });
          } else if (role == 'influencer') {
            await _firestore.collection('influencer_profiles').doc(user.uid).set({
              'uid': user.uid,
              'fullName': name,
              'contentCategory': '',
              'socialPlatform': extraData['platform'] ?? '',
              'socialUsername': '',
              'followers': 0,
              'priceRate': 0.0,
              'description': '',
              'portfolioUrl': '',
            });
          }
        }

        return newUser;
      }
    } catch (e) {
      print('Error in register: $e');
      rethrow;
    }
    return null;
  }

  // Login
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      User? user = result.user;
      
      if (user != null) {
        return await getCurrentUserData();
      }
    } catch (e) {
      print('Error in sign in: $e');
      rethrow;
    }
    return null;
  }

  // Logout
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error in sign out: $e');
      rethrow;
    }
  }

  // Lupa Password
  Future<void> resetPassword(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error in reset password: $e');
      rethrow;
    }
  }
}
