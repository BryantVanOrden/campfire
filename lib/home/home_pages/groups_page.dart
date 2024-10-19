// lib/home/home_pages/groups_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/group_card.dart';
import '../../screens/create_group_page.dart';

class GroupsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);

    return Scaffold(
      body: groupProvider.groups.isEmpty
          ? Center(
              child: Text(
                'No groups available. Create one!',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: groupProvider.groups.length,
              itemBuilder: (context, index) {
                final group = groupProvider.groups[index];
                return GroupCard(group: group);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to CreateGroupPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateGroupPage()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Create Group',
      ),
    );
  }
}
