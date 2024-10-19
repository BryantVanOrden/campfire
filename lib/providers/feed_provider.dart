import 'package:campfire/services/open_ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OpenAIService _openAIService = OpenAIService();

  List<String> _userGroupIds = [];
  List<DocumentSnapshot> _events = [];
  bool _isLoading = true;

  List<String> get userGroupIds => _userGroupIds;
  List<DocumentSnapshot> get events => _events;
  bool get isLoading => _isLoading;
bool _isInitialized = false;

  FeedProvider() {
    initialize();
  }



  void initialize() {
    if (!_isInitialized) {
      _isInitialized = true;
      print('FeedProvider initialized');
      _loadUserGroupIds();
      _listenToEvents();
    }
  }

  Future<void> _loadUserGroupIds() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        _userGroupIds = List<String>.from(userDoc['groupIds'] ?? []);
        notifyListeners();
      }
    }
  }

  void _listenToEvents() {
    _firestore.collection('events').snapshots().listen((snapshot) async {
      _events = snapshot.docs;
      _isLoading = false;

      // Call the OpenAI sorting method
      await _sortEventsByPreference();

      notifyListeners();
    });
  }

  // Method to manually refresh the events (used in pull-to-refresh)
  Future<void> refreshEvents() async {
    _isLoading = true; // Show loading indicator
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore.collection('events').get();
      _events = snapshot.docs;

      // Call the OpenAI sorting method
      await _sortEventsByPreference();
    } catch (e) {
      print('Error refreshing events: $e');
    }

    _isLoading = false; // Hide loading indicator
    notifyListeners();
  }

  Future<void> _sortEventsByPreference() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Fetch user data
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Prepare events data
      List<Map<String, dynamic>> eventList = _events.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'],
          'description': data['description'],
        };
      }).toList();

      // Call OpenAIService to get sorted event IDs
      try {
        List<String> sortedEventIds = await _openAIService.getSortedEventIds(
          user: userData,
          events: eventList,
        );

        // Reorder _events based on sortedEventIds
        List<DocumentSnapshot> sortedEvents = [];
        for (String eventId in sortedEventIds) {
          try {
            DocumentSnapshot eventDoc =
                _events.firstWhere((doc) => doc.id == eventId);
            sortedEvents.add(eventDoc);
          } catch (e) {
            // Event ID not found, skip
            print('Event ID $eventId not found in events list');
          }
        }

        // Update _events with sortedEvents
        _events = sortedEvents;
      } catch (e) {
        print('Error sorting events with OpenAI: $e');
      }
    }
  }
}
