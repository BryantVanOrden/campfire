import 'package:flutter/material.dart';
import '../data_structure/group_struct.dart';

class GroupCard extends StatelessWidget {
  final Group group;

  GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0), // Doubled margins
      child: ListTile(
        leading: CircleAvatar(
          radius: 50, // Doubled size of the avatar
          backgroundImage: group.imageUrl != null
              ? NetworkImage(group.imageUrl!)
              : null, // Show the image if available
          child: group.imageUrl == null
              ? Icon(Icons.group, size: 60) // Doubled size of the default icon
              : null,
        ),
        title: Text(
          group.name,
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold), // Doubled font size
        ),
        onTap: () {
          // Handle tap event
        },
      ),
    );
  }
}
