import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentalhouse_application/models/model.dart';

class LandlordDashboard extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Landlord Dashboard')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LandlordForm(),
          const SizedBox(height: 20),
          const Text('Pending Booking Requests:'),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('bookings').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No pending booking requests'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final booking = Booking.fromMap(
                      snapshot.data!.docs[index].data() as Map<String, dynamic>,
                      snapshot.data!.docs[index].id,
                    );
                    return BookingRequestItem(booking: booking);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BookingRequestItem extends StatelessWidget {
  final Booking booking;

  const BookingRequestItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('House ${booking.houseId}'),
      subtitle: Text('Tenant ${booking.tenantId}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () async {
              await _acceptBooking(context, booking);
            },
            child: const Text('Accept'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await _declineBooking(context, booking);
            },
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptBooking(BuildContext context, Booking booking) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id)
        .update({'status': true}); // Use boolean value true for accepted
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Booking accepted')));
  }

  Future<void> _declineBooking(BuildContext context, Booking booking) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id)
        .delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Booking declined')));
  }
}

class LandlordForm extends StatefulWidget {
  @override
  _LandlordFormState createState() => _LandlordFormState();
}

class _LandlordFormState extends State<LandlordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _roomTypeController = TextEditingController();
  File? _image;

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> submitHouse({
    required String address,
    required File image,
    required double price,
    required String roomType,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not logged in');
      return;
    }

    try {
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('images')
          .child('${DateTime.now()}.jpg');
      await ref.putFile(image);
      final String imageUrl = await ref.getDownloadURL();

      final house = {
        'id': user.uid,
        'address': address,
        'imageUrl': imageUrl,
        'price': price,
        'roomType': roomType,
      };

      await FirebaseFirestore.instance.collection('houses').add(house);
      print('House added successfully');
    } catch (e) {
      print('Error adding house: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price per Month'),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter the price';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _addressController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(labelText: 'Address'),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter the Address';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _roomTypeController,
            decoration: const InputDecoration(labelText: 'Type of Room'),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter the room type';
              }
              return null;
            },
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () {
              _selectImage();
            },
            child: const Text('Upload Image'),
          ),
          ElevatedButton(
            onPressed: () async {
              final address = _addressController.text;
              final price = double.tryParse(_priceController.text);
              final roomType = _roomTypeController.text;

              if (address == null || price == null || _image == null) {
                print('Invalid input');
                return;
              }

              await submitHouse(
                address: address,
                image: _image!,
                price: price,
                roomType: roomType,
              );

              _addressController.clear();
              _roomTypeController.clear();
              _priceController.clear();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
