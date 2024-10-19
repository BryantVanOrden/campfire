import 'package:flutter/material.dart';
import '../data_structure/group_struct.dart';

class GroupProvider with ChangeNotifier {
  List<Group> _groups = [];

  List<Group> get groups => _groups;

  void addGroup(Group group) {
    _groups.add(group);
    notifyListeners();
  }

  // Future methods for fetching groups from backend can be added here
}
