import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class House {
  final String id;
  final String address;
  final List<String> imageUrls;
  final double price;
  final String roomType;
  final double roomNumber;

  House({
    required this.id,
    required this.address,
    required this.imageUrls,
    required this.price,
    required this.roomType,
    required this.roomNumber,
  });

  factory House.fromMap(Map<String, dynamic>? data, String id) {
    return House(
      id: id,
      address: data?['address'],
      imageUrls: List<String>.from(data?['imageUrls'] ?? []),
      price: data?['price'].toDouble(),
      roomType: data?['roomType'],
      roomNumber: data?['roomNumber'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'imageUrls': imageUrls,
      'price': price,
      'roomType': roomType,
      'roomNumber': roomNumber,
    };
  }
}

class Tenant {
  final String id;
  final String name;
  final String email;

  Tenant({required this.id, required this.name, required this.email});

  factory Tenant.fromMap(Map<String, dynamic> data, String id) {
    return Tenant(
      id: id,
      name: data['name'],
      email: data['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
    };
  }
}

class Booking {
  final String id;
  final String houseId;
  final String tenantId;
  final bool status;
  final String moveInDate;
  final String duration;
  final String additionalRequirements;

  Booking(
      {required this.id,
      required this.houseId,
      required this.tenantId,
      required this.status,
      required this.moveInDate,
      required this.duration,
      required this.additionalRequirements});

  factory Booking.fromMap(Map<String, dynamic>? data, String id) {
    return Booking(
      id: id,
      houseId: data?['houseId'] ?? '',
      tenantId: data?['tenantId'] ?? '',
      status: data?['status'] ?? false,
      moveInDate: data?['moveInDate'] ?? '',
      duration: data?['duration'] ?? '',
      additionalRequirements: data?['additionalRequirements'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseId': houseId,
      'tenantId': tenantId,
      'status': status,
      'moveInDate': moveInDate,
      'duration': duration,
      'additionalRequirements': additionalRequirements
    };
  }
}

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String age;
  final String gender;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    required this.gender,
  });

  // Method to convert UserProfile object to a map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'age': age,
      'gender': gender,
    };
  }

  // Factory method to create UserProfile object from a map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      age: map['age'] ?? '',
      gender: map['gender'] ?? '',
    );
  }
}

class UserHelper {
  static FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> saveUser(User user) async {
    try {
      Map<String, dynamic> userData = {
        "name": user.displayName,
        "email": user.email,
        "last_login": user.metadata.lastSignInTime?.millisecondsSinceEpoch,
        "created_at": user.metadata.creationTime?.millisecondsSinceEpoch,
        "role": "user",
      };
      final userRef = _db.collection("users").doc(user.uid);
      if ((await userRef.get()).exists) {
        await userRef.update({
          "last_login": user.metadata.lastSignInTime?.millisecondsSinceEpoch,
        });
      } else {
        await userRef.set(userData);
      }
    } catch (error) {
      print("Error saving user data: $error");
      throw error; // Throw the error to handle it outside
    }
  }
}
