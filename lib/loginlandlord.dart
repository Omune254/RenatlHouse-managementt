import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentalhouse_application/Forgot_pw_Page.dart';
import 'package:rentalhouse_application/landLord_SignUp.dart';
import 'package:rentalhouse_application/landlord_page.dart';
import 'package:rentalhouse_application/models/model.dart';
import 'package:rentalhouse_application/resable_wigdets/resable_wigdet.dart';
import 'package:connectivity/connectivity.dart';
import 'package:rentalhouse_application/tenant_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextContoller = TextEditingController();

  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 74, 82, 90),
              Color.fromARGB(255, 232, 234, 236)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).size.height * 0.2,
              20,
              0,
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.lock,
                  size: 100,
                ),
                const Text(
                  'Welcome back you\'ve been missed!',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                reusableTextField(
                  "Enter Email",
                  Icons.email,
                  false,
                  _emailTextContoller,
                ),
                const SizedBox(height: 20),
                reusableTextField(
                  "Enter Password",
                  Icons.lock_outline,
                  true,
                  _passwordTextController,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                  ),
                ),
                const SizedBox(height: 20),
                SignInSignUpButton(context, true, () async {
                  var connectivityResult =
                      await Connectivity().checkConnectivity();
                  if (connectivityResult != ConnectivityResult.none) {
                    try {
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .signInWithEmailAndPassword(
                        email: _emailTextContoller.text,
                        password: _passwordTextController.text,
                      );

                      // Check user role after successful login
                      DocumentSnapshot userSnapshot = await FirebaseFirestore
                          .instance
                          .collection("users")
                          .doc(userCredential.user!.uid)
                          .get();
                      final userData = userSnapshot.data();
                      if (userData != null &&
                          userData is Map<String, dynamic> &&
                          userData['role'] == 'landlord') {
                        // User is a landlord, proceed to landlord dashboard
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LandlordDashboard(),
                          ),
                        );
                      } else {
                        // User is not a landlord, show error message
                        setState(() {
                          errorMessage =
                              'Access denied: You are not a landlord.';
                        });
                      }
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'user-not-found') {
                        errorMessage = 'User not found.';
                      } else if (e.code == 'wrong-password') {
                        errorMessage = 'Incorrect email or password.';
                      } else {
                        errorMessage = 'An error occurred. Please try again.';
                      }
                    }
                  } else {
                    errorMessage = 'No internet connection';
                  }
                  // Show error message if any
                  if (errorMessage.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                      ),
                    );
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
