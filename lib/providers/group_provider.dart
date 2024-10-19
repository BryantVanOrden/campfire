import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data_structure/group_struct.dart';

class GroupProvider with ChangeNotifier {
  List<Group> _groups = [];

  List<Group> get groups => _groups;

  void addGroup(Group group) {
    _groups.add(group);
    notifyListeners();
  }

  Future<void> fetchGroups() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('groups').get();
      _groups = snapshot.docs.map((doc) {
        return Group.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
      notifyListeners(); // Notify listeners to rebuild UI
    } catch (error) {
      print('Error fetching groups: $error');
    }
  }
  // Future methods for fetching groups from backend can be added here
}
