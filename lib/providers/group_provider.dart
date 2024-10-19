import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data_structure/group_struct.dart';

class GroupProvider with ChangeNotifier {
  List<Group> _groups = [];
  bool _isLoading = false;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;

  void addGroup(Group group) {
    _groups.add(group);
    notifyListeners();
  }

  // Method to fetch groups from Firestore
  Future<void> fetchGroups() async {
    _setLoading(true);
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('groups').get();
      _groups = snapshot.docs.map((doc) {
        return Group.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (error) {
      print('Error fetching groups: $error');
    } finally {
      _setLoading(false);
    }
  }

  // Method to refresh the groups (similar to fetchGroups, but can be triggered by pull-to-refresh)
  Future<void> refreshGroups() async {
    await fetchGroups(); // Reuse fetchGroups to refresh the groups
  }

  // Private method to update loading state
  void _setLoading(bool value) {
    _isLoading = value;
  }
}
