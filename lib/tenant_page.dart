import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/model.dart';
import 'user_util.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({Key? key}) : super(key: key);

  @override
  _TenantDashboardState createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late List<House> houses;
  late List<House> filteredHouses;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    houses = [];
    filteredHouses = [];
    searchController = TextEditingController();
    fetchHouses();
    searchController.addListener(filterHouses);
    checkAndNavigateToProfile();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> checkAndNavigateToProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bool profileComplete = await UserUtil.checkUserProfile(user);
      if (!profileComplete) {
        Navigator.pushNamed(context, '/profile_creation');
      }
    }
  }

  void fetchHouses() async {
    final snapshot = await firestore.collection('houses').get();
    setState(() {
      houses = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return House.fromMap(data, doc.id);
      }).toList();
      filteredHouses = List.from(houses); // Initialize filteredHouses
    });
  }

  void filterHouses() {
    final searchTerm = searchController.text.toLowerCase();
    setState(() {
      filteredHouses = houses.where((house) {
        return house.address.toLowerCase().contains(searchTerm) ||
            house.roomType.toLowerCase().contains(searchTerm);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text('Tenant Dashboard'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            floating: true, // App bar will disappear when scrolling down
            actions: [
              ProfileButton(),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 74, 82, 90),
                    Color.fromARGB(255, 232, 234, 236),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(10.5),
                        ),
                        hintText: 'Search by address or room type',
                        hintStyle: TextStyle(color: Colors.black87),
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  if (filteredHouses.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredHouses.length,
                      itemBuilder: (context, index) {
                        final house = filteredHouses[index];
                        return HouseListItem(house: house);
                      },
                    ),
                  if (filteredHouses.isEmpty && houses.isNotEmpty)
                    Center(child: Text('No results found')),
                  if (houses.isEmpty)
                    Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ],
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
                Text('Price: Ksh ${house.price}',
                    style: TextStyle(fontSize: 16)),
                Spacer(),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Colors.black26;
                        }
                        return const Color.fromARGB(255, 12, 1, 1);
                      }),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(38)))),
                  onPressed: () {
                    _showBookingForm(context, house);
                  },
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                        color: Color.fromARGB(221, 235, 232, 232),
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (house.imageUrls != null && house.imageUrls!.isNotEmpty)
              Column(
                children: [
                  for (var imageUrl in house.imageUrls!)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.network(imageUrl),
                    ),
                ],
              ),
            SizedBox(height: 10),
            if (house.roomType != null)
              Text('Room Type: ${house.roomType}',
                  style: TextStyle(fontSize: 16)),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 74, 82, 90),
            Color.fromARGB(255, 232, 234, 236),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
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
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 165, 161, 161)),
                      borderRadius: BorderRadius.circular(10.5),
                    ),
                    hintText: 'Move-In Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    hintStyle: TextStyle(color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
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
            const SizedBox(height: 10),
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 165, 161, 161)),
                  borderRadius: BorderRadius.circular(10.5),
                ),
                hintText: 'Duration of Stay',
                hintStyle: TextStyle(color: Colors.black87),
                filled: true,
                fillColor: Colors.white,
              ),
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
            const SizedBox(height: 10),
            TextFormField(
              controller: _additionalRequirementsController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 165, 161, 161)),
                  borderRadius: BorderRadius.circular(10.5),
                ),
                hintText: 'Additional Requirements',
                hintStyle: TextStyle(color: Colors.black87),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _submitBookingRequest(context);
                }
              },
              child: const Text(
                'Submit Booking Request',
                style: TextStyle(
                    color: Color.fromARGB(221, 235, 232, 232),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
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
