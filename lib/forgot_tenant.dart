import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentalhouse_application/resable_wigdets/resable_wigdet.dart';

class ForgotPasswordPageTenant extends StatefulWidget {
  const ForgotPasswordPageTenant({super.key});

  @override
  State<ForgotPasswordPageTenant> createState() =>
      _ForgotPasswordPageTenantState();
}

class _ForgotPasswordPageTenantState extends State<ForgotPasswordPageTenant> {
  final _emailTextController = TextEditingController();

  @override
  void dispose() {
    _emailTextController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailTextController.text.trim());
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Password link sent! Check your email'),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(e.message.toString()),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 2, 24, 43),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Color.fromARGB(255, 74, 82, 90),
            Color.fromARGB(255, 232, 234, 236)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                const Text(
                  'Enter your email and we will send you a password reset link',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField('Enter Email Id', Icons.person_2_outlined,
                    false, _emailTextController),
                const SizedBox(
                  height: 20,
                ),
                MaterialButton(
                  onPressed: passwordReset,
                  child: Text('Reset Password'),
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
