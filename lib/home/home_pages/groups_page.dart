import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/group_card.dart';
import '../../screens/create_group_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> userGroupIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserGroups();
    _fetchGroups(); // Fetch groups on page load
  }

  Future<void> _loadUserGroups() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userGroupIds = List<String>.from(userDoc['groupIds'] ?? []);
      });
    }
  }

  Future<void> _fetchGroups() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.fetchGroups(); // Fetch groups from Firestore
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);

    // Filter groups by user's groupIds
    final myGroups = groupProvider.groups
        .where((group) => userGroupIds.contains(group.groupId))
        .toList();
    final publicGroups = groupProvider.groups
        .where((group) => !userGroupIds.contains(group.groupId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black, 
          labelColor: Colors.black, 
          unselectedLabelColor: Colors.grey, 
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Public Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My Groups Tab
          myGroups.isEmpty
              ? const Center(
                  child: Text(
                    'No groups available. Join or create one!',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: myGroups.length,
                  itemBuilder: (context, index) {
                    final group = myGroups[index];
                    return GroupCard(group: group);
                  },
                ),

          // Public Groups Tab
          publicGroups.isEmpty
              ? const Center(
                  child: Text(
                    'No public groups available.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: publicGroups.length,
                  itemBuilder: (context, index) {
                    final group = publicGroups[index];
                    return GroupCard(group: group);
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to CreateGroupPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupPage()),
          );
        },
        tooltip: 'Create Group',
        child: const Icon(Icons.add),
      ),
    );
  }
}
