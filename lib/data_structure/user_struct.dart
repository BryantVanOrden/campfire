import 'package:latlong2/latlong.dart'; // Import LatLng for location

class User {
  String uid;
  String email;
  List<String>? interests;
  List<String>? groupIds;
  String? profileImageLink;
  DateTime dateOfBirth;
  String displayName;
  LatLng location;
  String? callOffer; // Nullable string to store SDP offer
  String? callAnswer; // Nullable string to store SDP answer
  List<Map<String, dynamic>>? iceCandidates; // To store ICE candidates

  User({
    required this.uid,
    required this.email,
    this.interests,
    this.groupIds,
    this.profileImageLink,
    required this.dateOfBirth,
    required this.displayName,
    required this.location,
    this.callOffer,
    this.callAnswer,
    this.iceCandidates,
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
      'displayName': displayName,
      'callOffer': callOffer,
      'callAnswer': callAnswer,
      'iceCandidates': iceCandidates,
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
      displayName: json["displayName"],
      callOffer: json['callOffer'],
      callAnswer: json['callAnswer'],
      iceCandidates: json['iceCandidates']?.cast<Map<String, dynamic>>(),
    );
  }
}
