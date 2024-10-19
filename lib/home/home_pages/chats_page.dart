import 'package:campfire/screens/couple_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatsPage extends StatefulWidget {
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
    _fetchUsers(); // Fetch users on initialization
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
        String email = userDoc['email'] ?? '';
        return email.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _openChat(DocumentSnapshot userDoc) {
  // Cast the document data to Map<String, dynamic>
  Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

  // Use a default profile picture if 'photoURL' is missing
  String? otherUserPhotoUrl = userData.containsKey('photoURL')
      ? userData['photoURL']
      : null;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CoupleChatPage(
        otherUserId: userData['uid'],
        otherUserName: userData['email'] ?? 'Unknown', // Using email for displayName
        otherUserPhotoUrl: otherUserPhotoUrl, // Safe to use default or actual photoURL
      ),
    ),
  );
}



  // Helper function to get user profile image
  ImageProvider _getUserImage(DocumentSnapshot userDoc) {
    var data = userDoc.data() as Map<String, dynamic>;
    String? photoURL = data['photoURL'];

    if (photoURL != null && photoURL.isNotEmpty) {
      return NetworkImage(photoURL);
    } else {
      return AssetImage('assets/images/default_profile_pic.jpg');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                  labelText: 'Search by Email',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder()),
              onChanged: _searchUsers,
            ),
          ),
          // Users List
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(child: Text('No users found'))
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      var userDoc = filteredUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: _getUserImage(userDoc),
                        ),
                        title: Text(userDoc['email'] ?? 'Unknown'), // Using email
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
