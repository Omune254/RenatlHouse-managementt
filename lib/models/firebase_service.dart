import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  Future<void> createUserDocument(
      String userId, String email, String role) async {
    try {
      if (userId.isEmpty || email.isEmpty || role.isEmpty) {
        throw Exception('User ID, email, or role cannot be empty.');
      }

      // Add additional validation as needed

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'email': email,
        'role': role,
        // Add more fields as needed
      });
    } catch (e) {
      print('Error creating user document: $e');
      throw e; // Rethrow the exception to propagate it to the caller
    }
  }

  // Add other Firebase-related functions here
}
