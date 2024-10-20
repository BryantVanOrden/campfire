import 'package:campfire/screens/couple_chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key})
      : super(key: key); // Use 'Key' if using null-safety

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> users = [];
  List<DocumentSnapshot> filteredUsers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when the page initializes
  }

  Future<void> _fetchUsers() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Fetch groups where the current user is a member
    QuerySnapshot groupSnapshot = await _firestore
        .collection('groups')
        .where('members', arrayContains: currentUser.uid)
        .get();

    Set<String> memberIds = {};

    // Collect UIDs of all members in these groups
    for (var groupDoc in groupSnapshot.docs) {
      List<dynamic> members = groupDoc['members'] ?? [];
      memberIds.addAll(members.map((e) => e.toString()));
    }

    // Remove the current user's UID
    memberIds.remove(currentUser.uid);

    // Fetch user details of these members
    if (memberIds.isNotEmpty) {
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('uid', whereIn: memberIds.toList())
          .get();

      setState(() {
        users = userSnapshot.docs;
        filteredUsers = users;
      });
    }
  }

  void _searchUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = users.where((userDoc) {
        String name = userDoc['displayName'] ?? '';
        return name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _openChat(DocumentSnapshot userDoc) {
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String? otherUserPhotoUrl =
        userData.containsKey('photoURL') ? userData['photoURL'] : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoupleChatPage(
          otherUserId: userData['uid'],

          otherUserName: userData['displayName'] ?? 'Unknown',
          otherUserPhotoUrl: otherUserPhotoUrl, // Using profileImageLink
        ),
      ),
    );
  }

  // Helper function to get user profile image
  ImageProvider _getUserImage(DocumentSnapshot userDoc) {
    var data = userDoc.data() as Map<String, dynamic>;
    String? profileImageLink = data['profileImageLink'];

    if (profileImageLink != null && profileImageLink.isNotEmpty) {
      return NetworkImage(profileImageLink);
    } else {
      return const AssetImage('assets/images/default_profile_pic.jpg');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Username',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
          ),
          // Users List
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      var userDoc = filteredUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: _getUserImage(userDoc),
                        ),
                        title: Text(userDoc['displayName'] ?? 'Unknown'),
                        onTap: () => _openChat(userDoc),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
