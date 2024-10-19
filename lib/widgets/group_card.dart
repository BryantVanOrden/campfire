import 'package:flutter/material.dart';
import '../data_structure/group_struct.dart';

class GroupCard extends StatelessWidget {
  final Group group;

  GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(group.name),
        subtitle: Text('Group ID: ${group.groupId}'),
        onTap: () {
          // Handle tap event
        },
      ),
    );
  }
}
