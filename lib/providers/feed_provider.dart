// lib/providers/feed_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _userGroupIds = [];
  List<DocumentSnapshot> _events = [];
  bool _isLoading = true;

  List<String> get userGroupIds => _userGroupIds;
  List<DocumentSnapshot> get events => _events;
  bool get isLoading => _isLoading;

  FeedProvider() {
    _loadUserGroupIds();
    _listenToEvents();
  }

  Future<void> _loadUserGroupIds() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        _userGroupIds = List<String>.from(userDoc['groupIds'] ?? []);
        notifyListeners();
      }
    }
  }

  void _listenToEvents() {
    _firestore.collection('events').snapshots().listen((snapshot) {
      _events = snapshot.docs;
      _isLoading = false;
      notifyListeners();
    });
  }
}
