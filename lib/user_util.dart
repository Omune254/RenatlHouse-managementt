import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserUtil {
  static Future<bool> checkUserProfile(User? user) async {
    if (user == null) {
      return false;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> userData =
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(user.uid)
              .get();

      if (!userData.exists) {
        // User profile does not exist
        return false;
      }

      // Check if 'profileComplete' field exists and is of type bool
      final bool profileComplete = (userData.data() != null &&
              userData.data()!['profileComplete'] is bool)
          ? userData.data()!['profileComplete'] as bool
          : false;

      return profileComplete;
    } catch (e) {
      print('Error checking user profile: $e');
      return false;
    }
  }
}
