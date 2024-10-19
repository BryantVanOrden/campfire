import 'package:latlong2/latlong.dart'; // Import LatLng for location

class User {
  String uid;
  String email;
  List<String>? interests; // Nullable list of interests
  List<String>? groupIds; // Nullable list of group IDs
  String? profileImageLink; // Nullable link to profile image stored in Firebase
  DateTime dateOfBirth;
  LatLng location; // LatLng object for location

  User({
    required this.uid,
    required this.email,
    this.interests,
    this.groupIds,
    this.profileImageLink,
    required this.dateOfBirth,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'interests': interests,
      'groupIds': groupIds,
      'profileImageLink': profileImageLink,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      email: json['email'],
      interests: json['interests']?.cast<String>(),
      groupIds: json['groupIds']?.cast<String>(),
      profileImageLink: json['profileImageLink'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      location: LatLng(
        json['location']['latitude'],
        json['location']['longitude'],
      ),
    );
  }
}
