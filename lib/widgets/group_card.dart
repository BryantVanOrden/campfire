import 'package:campfire/screens/group_chat_page.dart';
import 'package:flutter/material.dart';
import '../data_structure/group_struct.dart';


class GroupCard extends StatelessWidget {
  final Group group;

  const GroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 50, 
          backgroundImage: group.imageUrl != null
              ? NetworkImage(group.imageUrl!)
              : null, 
          child: group.imageUrl == null
              ? const Icon(Icons.group, size: 60)
              : null,
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          // Navigate to GroupChatPage when the group card is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatPage(groupId: group.groupId, groupName: group.name),
            ),
          );
        },
      ),
    );
  }
}
