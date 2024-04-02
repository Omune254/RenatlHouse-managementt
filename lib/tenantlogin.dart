import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentalhouse_application/forgot_tenant.dart';
import 'package:rentalhouse_application/profile_creation_form.dart';
import 'package:rentalhouse_application/resable_wigdets/resable_wigdet.dart';
import 'package:rentalhouse_application/tenantSignUp.dart';
import 'package:rentalhouse_application/tenant_page.dart';
import 'package:connectivity/connectivity.dart';

class MyLoginScreen extends StatefulWidget {
  const MyLoginScreen({Key? key});

  @override
  State<MyLoginScreen> createState() => _MyLoginScreenState();
}

class _MyLoginScreenState extends State<MyLoginScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextContoller = TextEditingController();

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
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return ForgotPasswordPageTenant();
                              },
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color.fromARGB(255, 22, 1, 1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SignInSignUpButton(context, true, () async {
                  var connectivityResult =
                      await Connectivity().checkConnectivity();
                  if (connectivityResult != ConnectivityResult.none) {
                    FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                            email: _emailTextContoller.text,
                            password: _passwordTextController.text)
                        .then((value) async {
                      // Check if the user's profile exists in Firestore
                      final userProfileSnapshot = await FirebaseFirestore
                          .instance
                          .collection('profiles')
                          .doc(value.user!.uid)
                          .get();

                      if (userProfileSnapshot.exists) {
                        // Profile exists, navigate to tenant dashboard
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TenantDashboard()));
                      } else {
                        // Profile doesn't exist, navigate to profile creation form
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileCreationForm(),
                          ),
                        );
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logged in successfully'),
                        ),
                      );
                    }).onError((error, stackTrace) {
                      print('Error ${error.toString()}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Incorrect email or password. Please try again.'),
                        ),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No internet connection'),
                      ),
                    );
                  }
                }),
                signUpOption()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: Color.fromARGB(179, 14, 13, 13)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const TenantSignUp()));
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(
                color: Color.fromARGB(255, 15, 15, 15),
                fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}
