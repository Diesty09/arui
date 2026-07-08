import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage(File file, String uid, String role) async {
    try {
      // Create a reference to the location you want to upload to in firebase
      // Example: profile_images/umkm/uid.jpg
      String fileExtension = file.path.split('.').last;
      String filePath = 'profile_images/$role/${uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      Reference reference = _storage.ref().child(filePath);
      
      // Upload the file
      UploadTask uploadTask = reference.putFile(file);
      
      // Wait until the upload is complete
      TaskSnapshot snapshot = await uploadTask;
      
      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<String?> uploadContentImage(File file, String offerId, String type) async {
    try {
      String fileExtension = file.path.split('.').last;
      String filePath = 'content_proofs/$offerId/${type}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      Reference reference = _storage.ref().child(filePath);
      UploadTask uploadTask = reference.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading content image: $e');
      return null;
    }
  }
}
