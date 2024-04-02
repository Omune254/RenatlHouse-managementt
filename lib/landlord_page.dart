import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentalhouse_application/models/model.dart';

class LandlordDashboard extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  LandlordDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landlord Dashboard'),
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
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add House:',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),
                const LandlordForm(),
                const SizedBox(height: 40.0),
                const Text(
                  'Pending Booking Requests:',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),
                StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('bookings').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('No pending booking requests'));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final booking = Booking.fromMap(
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>,
                          snapshot.data!.docs[index].id,
                        );
                        return BookingRequestItem(booking: booking);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookingRequestItem extends StatelessWidget {
  final Booking booking;

  const BookingRequestItem({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('houses')
          .doc(booking.houseId)
          .get(),
      builder: (context, houseSnapshot) {
        if (houseSnapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text('Loading...'),
          );
        }
        if (houseSnapshot.hasError) {
          return ListTile(
            title: Text('Error: ${houseSnapshot.error}'),
          );
        }
        final houseData = houseSnapshot.data!.data() as Map<String, dynamic>;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('profiles')
              .doc(booking.tenantId)
              .get(),
          builder: (context, tenantSnapshot) {
            if (tenantSnapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                title: Text('Loading...'),
              );
            }
            if (tenantSnapshot.hasError) {
              return ListTile(
                title: Text('Error: ${tenantSnapshot.error}'),
              );
            }
            final tenantData =
                tenantSnapshot.data!.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(
                  'House ${houseData['roomNumber']} - RoomType ${houseData['roomType']}'),
              subtitle:
                  Text('Tenant ${tenantData['name']} - ${tenantData['email']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(),
                    onPressed: () async {
                      await _acceptBooking(context, booking);
                    },
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                          color: Color.fromARGB(221, 12, 12, 12),
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await _declineBooking(context, booking);
                    },
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                          color: Color.fromARGB(221, 8, 8, 8),
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
  const LandlordForm({super.key});

  @override
  _LandlordFormState createState() => _LandlordFormState();
}

class _LandlordFormState extends State<LandlordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _roomTypeController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  final List<File> _images = [];

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _images.add(File(pickedFile.path));
      }
    });
  }

  Widget _buildImageList() {
    return SizedBox(
      height: 100.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.file(_images[index]),
          );
        },
      ),
    );
  }

  Future<void> submitHouse({
    required String address,
    required List<File> images,
    required double price,
    required String roomType,
    required double roomNumber,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not logged in');
      return;
    }

    try {
      List<String> imageUrls = [];

      for (File image in images) {
        final Reference ref = FirebaseStorage.instance
            .ref()
            .child('images')
            .child('${DateTime.now()}_${_images.indexOf(image)}.jpg');
        await ref.putFile(image);
        final String imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      final house = {
        'id': user.uid,
        'address': address,
        'imageUrls': imageUrls,
        'price': price,
        'roomType': roomType,
        'roomNumber': roomNumber, // Include room number in the house data
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
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.price_check_sharp),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(10.5),
              ),
              hintText: 'Price per Month',
              hintStyle: TextStyle(color: Colors.black87),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter the price';
              }
              return null;
            },
          ),
          SizedBox(height: 20.0),
          TextFormField(
            controller: _addressController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.location_city),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(10.5),
              ),
              hintText: 'Address',
              hintStyle: TextStyle(color: Colors.black87),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter the Address';
              }
              return null;
            },
          ),
          SizedBox(height: 20.0),
          TextFormField(
            controller: _roomTypeController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.house),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(10.5),
              ),
              hintText: 'Type of Room',
              hintStyle: TextStyle(color: Colors.black87),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter the room type';
              }
              return null;
            },
          ),
          SizedBox(height: 20.0),
          TextFormField(
            controller: _roomNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(255, 165, 161, 161)),
                borderRadius: BorderRadius.circular(10.5),
              ),
              hintText: 'Room Number',
              hintStyle: TextStyle(color: Colors.black87),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter the room number';
              }
              return null;
            },
          ),
          SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () {
              _selectImage();
            },
            child: Text(
              'Upload Image',
              style: TextStyle(
                  color: Color.fromARGB(221, 10, 10, 10),
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          SizedBox(height: 20.0),
          _images.isNotEmpty ? _buildImageList() : SizedBox(),
          SizedBox(height: 10.0),
          ElevatedButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.pressed)) {
                    return Colors.black26;
                  }
                  return const Color.fromARGB(255, 12, 1, 1);
                }),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(38)))),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final address = _addressController.text;
                final priceText = _priceController.text;
                final roomType = _roomTypeController.text;
                final roomNumberText = _roomNumberController.text;

                if (priceText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter the price')),
                  );
                  return;
                }
                final price = double.tryParse(priceText);
                if (price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid price format')),
                  );
                  return;
                }

                if (roomNumberText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter the room number')),
                  );
                  return;
                }
                final roomNumber = double.tryParse(roomNumberText);
                if (roomNumber == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid room number format')),
                  );
                  return;
                }

                if (_images.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select at least one image')),
                  );
                  return;
                }

                await submitHouse(
                  address: address,
                  images: _images,
                  price: price,
                  roomType: roomType,
                  roomNumber: roomNumber,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('House submitted successfully')),
                );

                _addressController.clear();
                _roomTypeController.clear();
                _priceController.clear();
                _roomNumberController.clear();
                setState(() {
                  _images.clear();
                });
              }
            },
            child: const Text(
              'Submit',
              style: TextStyle(
                  color: Color.fromARGB(221, 235, 232, 232),
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
