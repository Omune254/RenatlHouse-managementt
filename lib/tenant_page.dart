import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/model.dart';

class TenantDashboard extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Dashboard'),
        actions: [
          ProfileButton(),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: firestore.collection('houses').get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final house = House.fromMap(
                  snapshot.data!.docs[index].data() as Map<String, dynamic>?,
                  snapshot.data!.docs[index].id,
                );
                return HouseListItem(house: house);
              },
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class ProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return IconButton(
      onPressed: () {
        if (user == null) {
          Navigator.pushNamed(context, '/login');
        } else {
          Navigator.pushNamed(context, '/profile_creation');
        }
      },
      icon: Icon(Icons.account_circle),
    );
  }
}

class HouseListItem extends StatelessWidget {
  final House house;

  const HouseListItem({required this.house});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              house.address,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text('Price: \$${house.price}', style: TextStyle(fontSize: 16)),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    _showBookingForm(context, house);
                  },
                  child: Text('Book Now'),
                ),
              ],
            ),
            SizedBox(height: 10),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('houses')
                  .doc(house.id)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.hasData && snapshot.data != null) {
                  final houseData = snapshot.data!;
                  final imageUrl = houseData['imageUrl'] as String?;
                  final roomType = houseData['roomType'] as String?;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null) Image.network(imageUrl),
                      if (roomType != null) Text('Room Type: $roomType'),
                    ],
                  );
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingForm(BuildContext context, House house) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: BookingRequestForm(house: house),
        );
      },
    );
  }
}

class BookingRequestForm extends StatefulWidget {
  final House house;

  BookingRequestForm({required this.house});

  @override
  _BookingRequestFormState createState() => _BookingRequestFormState();
}

class _BookingRequestFormState extends State<BookingRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _moveInDateController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _additionalRequirementsController =
      TextEditingController();

  @override
  void dispose() {
    _moveInDateController.dispose();
    _durationController.dispose();
    _additionalRequirementsController.dispose();
    super.dispose();
  }

  Future<void> _selectMoveInDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _moveInDateController.text = pickedDate.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'House Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Address: ${widget.house.address}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            InkWell(
              onTap: () {
                _selectMoveInDate(context);
              },
              child: IgnorePointer(
                child: TextFormField(
                  controller: _moveInDateController,
                  decoration: InputDecoration(
                    labelText: 'Move-In Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the move-in date';
                    }
                    return null;
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(labelText: 'Duration of Stay'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the duration of stay';
                }
                final duration = int.tryParse(value);
                if (duration == null || duration <= 0) {
                  return 'Please enter a valid duration of stay';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _additionalRequirementsController,
              decoration: InputDecoration(labelText: 'Additional Requirements'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _submitBookingRequest(context);
                }
              },
              child: Text('Submit Booking Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitBookingRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to submit booking request')),
      );
      return;
    }

    final moveInDate = _moveInDateController.text;
    final duration = _durationController.text;
    final additionalRequirements = _additionalRequirementsController.text;

    final booking = Booking(
      id: '',
      houseId: widget.house.id,
      tenantId: user.uid,
      moveInDate: moveInDate,
      duration: duration,
      additionalRequirements: additionalRequirements,
      status: false,
    );

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .add(booking.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking request submitted successfully')),
      );
      _moveInDateController.clear();
      _durationController.clear();
      _additionalRequirementsController.clear();
      Navigator.of(context).pop();
    } catch (error) {
      print('Error submitting booking request: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to submit booking request. Please try again later.'),
        ),
      );
    }
  }
}
