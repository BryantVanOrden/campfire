import 'package:latlong2/latlong.dart'; // Import LatLng for location
import 'package:flutter_webrtc/flutter_webrtc.dart'; // For RTCIceCandidate

class User {
  String uid;
  String email;
  List<String>? interests;
  List<String>? groupIds;
  String? profileImageLink;
  DateTime dateOfBirth;
  LatLng location;
  String? callOffer; // Nullable string to store SDP offer
  String? callAnswer; // Nullable string to store SDP answer
  List<RTCIceCandidate>? iceCandidates; // Store RTCIceCandidates directly

  User({
    required this.uid,
    required this.email,
    this.interests,
    this.groupIds,
    this.profileImageLink,
    required this.dateOfBirth,
    required this.location,
    this.callOffer,
    this.callAnswer,
    this.iceCandidates,
  });

  // Convert the User object to JSON (e.g., for Firestore storage)
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
      'callOffer': callOffer,
      'callAnswer': callAnswer,
      // Convert iceCandidates to a List of Maps to store in Firestore
      'iceCandidates': iceCandidates
          ?.map((candidate) => {
                'candidate': candidate.candidate,
                'sdpMid': candidate.sdpMid,
                'sdpMLineIndex': candidate.sdpMLineIndex,
              })
          .toList(),
    };
  }

  // Convert JSON data to a User object
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
      callOffer: json['callOffer'],
      callAnswer: json['callAnswer'],
      // Convert the JSON iceCandidates list back into a list of RTCIceCandidate objects
      iceCandidates: json['iceCandidates'] != null
          ? (json['iceCandidates'] as List)
              .map((c) => RTCIceCandidate(
                    c['candidate'],
                    c['sdpMid'],
                    c['sdpMLineIndex'],
                  ))
              .toList()
          : null,
    );
  }
}
