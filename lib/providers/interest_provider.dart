// interest_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterestProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _userInterests = [];
  bool _isLoading = false; // Initialize to false

  List<String> get userInterests => _userInterests;
  bool get isLoading => _isLoading;

  InterestProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // User is signed out, clear data
        _userInterests = [];
        notifyListeners();
      } else {
        // User is signed in, fetch interests
        _getInterests();
      }
    });
  }

  Future<bool> checkInterest() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        List<dynamic>? interests = userDoc['interests'];
        return interests != null && interests.isNotEmpty;
      }
    }
    return false;
  }

  Future<void> _getInterests() async {
    _isLoading = true;
    notifyListeners();

    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        _userInterests = List<String>.from(userDoc['interests'] ?? []);
      }
    }

    _isLoading = false;
    notifyListeners();
  }


  // Expose getInterests method
  Future<void> getInterests() async {
    await _getInterests();
  }

  // Method to post/update interests
  Future<void> postInterests(List<String> interests) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'interests': interests});
      _userInterests = interests;
      notifyListeners();
    }
  }

  // Method to edit interests
  Future<void> editInterests(List<String> interests) async {
    await postInterests(interests);
  }

  // Method to delete interests
  Future<void> deleteInterests() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'interests': []});
      _userInterests = [];
      notifyListeners();
    }
  }
}
