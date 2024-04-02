import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rentalhouse_application/Home_page.dart';
import 'package:rentalhouse_application/profile_creation_form.dart';
import 'package:rentalhouse_application/tenantlogin.dart';
import 'package:rentalhouse_application/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Retrieve device token and update Firestore
  await retrieveDeviceTokenAndUpdateFirestore();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rental Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(),
        '/login': (context) => MyLoginScreen(),
        '/profile_creation': (context) => ProfileCreationForm(),
      },
    );
  }
}

Future<void> retrieveDeviceTokenAndUpdateFirestore() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? deviceToken = await messaging.getToken();
    if (deviceToken != null) {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update Firestore document with device token
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .update({'deviceToken': deviceToken});
        print('Device token updated successfully');
      } else {
        print('No user signed in');
      }
    } else {
      print('Unable to retrieve device token');
    }
  } catch (e) {
    print('Error: $e');
  }
}
