import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class User {
  String uid;
  String email;
  List<String>? interests;
  List<String>? groupIds;
  String? profileImageLink;
  DateTime dateOfBirth;
  LatLng location;
  String? callOffer;
  String? callAnswer;
  List<RTCIceCandidate>? iceCandidates;

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

  // Convert the User object to JSON for Firestore
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
      'iceCandidates': iceCandidates?.map((candidate) => {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      }).toList(),
    };
  }

  // Convert Firestore JSON to a User object
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

  // Save user data to Firestore
  Future<void> saveToFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(uid).set(toJson());
  }

  // Fetch user data from Firestore
  static Future<User?> fetchFromFirestore(String uid) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return User.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Update user's callOffer and callAnswer in Firestore
  Future<void> updateCallData({String? newCallOffer, String? newCallAnswer}) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Map<String, dynamic> updateData = {};
    if (newCallOffer != null) {
      updateData['callOffer'] = newCallOffer;
    }
    if (newCallAnswer != null) {
      updateData['callAnswer'] = newCallAnswer;
    }
    await firestore.collection('users').doc(uid).update(updateData);
  }

  // Update user's ICE candidates in Firestore
  Future<void> updateIceCandidates(List<RTCIceCandidate> candidates) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(uid).update({
      'iceCandidates': candidates.map((candidate) => {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      }).toList(),
    });
  }
}
