import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentalhouse_application/Profile_screen.dart';
import 'package:rentalhouse_application/models/model.dart';

class ProfileCreationForm extends StatefulWidget {
  @override
  _ProfileCreationFormState createState() => _ProfileCreationFormState();
}

class _ProfileCreationFormState extends State<ProfileCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Creation'),
      ),
      body: Container(
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(10.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Name',
                    hintStyle: TextStyle(color: Colors.black87),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(10.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.black87),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(10.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Phone number',
                    hintStyle: TextStyle(color: Colors.black87),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(10.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Age',
                    hintStyle: TextStyle(color: Colors.black87),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(10.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Gender',
                    hintStyle: TextStyle(color: Colors.black87),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                            child: Text(gender),
                            value: gender,
                          ))
                      .toList(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _submitProfile(context);
                    }
                  },
                  child: Text(
                    'Save Profile',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitProfile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle the case when user is not logged in
      return;
    }

    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text;
    final age = _ageController.text;

    final profile = UserProfile(
      userId: user.uid,
      name: name,
      email: email,
      phone: phone,
      age: age,
      gender: _selectedGender ?? '', // Use the selected gender
    );

    try {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .set(profile.toMap());

      final profileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();

      final updatedProfile =
          UserProfile.fromMap(profileSnapshot.data() as Map<String, dynamic>);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved successfully')),
      );

      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _ageController.clear();

      Navigator.of(context).pop();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(profile: updatedProfile),
        ),
      );
    } catch (error) {
      print('Error saving profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile. Please try again later.'),
        ),
      );
    }
  }
}
