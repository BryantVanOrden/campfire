import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../widgets/group_card.dart';
import 'create_group_page.dart';


class GroupTestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Group Test Page')),
      body: groupProvider.groups.isEmpty
          ? Center(child: Text('No groups available. Create one!'))
          : ListView.builder(
              itemCount: groupProvider.groups.length,
              itemBuilder: (context, index) {
                final group = groupProvider.groups[index];
                return GroupCard(group: group);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateGroupPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
