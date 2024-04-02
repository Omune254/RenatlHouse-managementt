import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentalhouse_application/resable_wigdets/resable_wigdet.dart';
import 'package:rentalhouse_application/tenant_page.dart';
import 'package:connectivity/connectivity.dart';

class TenantSignUp extends StatefulWidget {
  const TenantSignUp({Key? key});

  @override
  State<TenantSignUp> createState() => _TenantSignUpState();
}

class _TenantSignUpState extends State<TenantSignUp> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextContoller = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
          Color.fromARGB(255, 74, 82, 90),
          Color.fromARGB(255, 232, 234, 236)
        ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter UserName", Icons.person_2_outlined,
                    false, _userNameTextController),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter Email Id", Icons.person_2_outlined,
                    false, _emailTextContoller),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter password", Icons.lock_outline, true,
                    _passwordTextController),
                const SizedBox(
                  height: 20,
                ),
                SignInSignUpButton(context, false, () async {
                  var connectivityResult =
                      await Connectivity().checkConnectivity();
                  if (connectivityResult != ConnectivityResult.none) {
                    _auth
                        .createUserWithEmailAndPassword(
                            email: _emailTextContoller.text,
                            password: _passwordTextController.text)
                        .then((userCredential) {
                      // Create user document in Firestore
                      _createUserDocument(userCredential.user!.uid,
                          _emailTextContoller.text, 'tenant');
                      print("created new account");
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TenantDashboard()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Signed up successfully'),
                        ),
                      );
                    }).catchError((error) {
                      print("Error ${error.toString()}");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sign up failed. Please try again.'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createUserDocument(String userId, String email, String role) {
    // Store additional user information in Firestore
    // Example code to store user role
    FirebaseFirestore.instance.collection('users').doc(userId).set({
      'email': email,
      'role': role,
    }).catchError((error) {
      print('Error creating user document: $error');
      // Handle error
    });
  }
}
