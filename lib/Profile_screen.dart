import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentalhouse_application/models/model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key, required UserProfile profile})
      : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;

  late UserProfile _userProfile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _ageController = TextEditingController();
    _genderController = TextEditingController();
    _fetchProfileData(); // Fetch user details when the screen is initialized
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();
        setState(() {
          _userProfile = UserProfile.fromMap(
              profileSnapshot.data() as Map<String, dynamic>);
          _nameController.text = _userProfile.name;
          _emailController.text = _userProfile.email;
          _phoneController.text = _userProfile.phone;
          _ageController.text = _userProfile.age;
          _genderController.text = _userProfile.gender;
        });
      }
    } catch (error) {
      print('Error fetching profile data: $error');
    }
  }

  Future<void> _updateProfileData() async {
    // Implementation of updating profile data...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            onPressed: () {
              _updateProfileData();
            },
            icon: Icon(Icons.save),
          ),
        ],
      ),
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
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
              ),
              TextField(
                controller: _genderController,
                decoration: InputDecoration(labelText: 'Gender'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
