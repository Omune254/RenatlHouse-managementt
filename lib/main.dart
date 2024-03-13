import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rentalhouse_application/Home_page.dart';
import 'package:rentalhouse_application/profile_creation_form.dart';
import 'package:rentalhouse_application/tenantlogin.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rental aplication',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Define initial route
      routes: {
        '/': (context) => const MyHomePage(), // Your main page
        '/login': (context) => MyLoginScreen(), // Your login page
        '/profile_creation': (context) =>
            ProfileCreationForm(), // Your profile creation page
      },
    );
  }
}
