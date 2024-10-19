import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatAdminPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatAdminPage({super.key, required this.groupId, required this.groupName});

  @override
  _GroupChatAdminPageState createState() => _GroupChatAdminPageState();
}

class _GroupChatAdminPageState extends State<GroupChatAdminPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> publicUsers = [];
  List<DocumentSnapshot> members = [];
  List<String> bannedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    // Load the public members, group members, and banned users
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
    if (groupDoc.exists) {
      List<String> publicMemberIds = List<String>.from(groupDoc['publicMembers'] ?? []);
      List<String> memberIds = List<String>.from(groupDoc['members'] ?? []);
      List<String> bannedIds = List<String>.from(groupDoc['bannedUids'] ?? []);

      setState(() {
        bannedUsers = bannedIds;
      });

      // Fetch details for public users
      for (String userId in publicMemberIds) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            publicUsers.add(userDoc);
          });
        }
      }

      // Fetch details for members
      for (String userId in memberIds) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            members.add(userDoc);
          });
        }
      }
    }
  }

  Future<void> _addUserToMembers(String userId) async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'members': FieldValue.arrayUnion([userId]),
      'publicMembers': FieldValue.arrayRemove([userId])
    });

    setState(() {
      // Move the user from public to members list
      publicUsers.removeWhere((user) => user.id == userId);
      _loadGroupData(); // Reload to reflect changes
    });
  }

  Future<void> _banUser(String userId) async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'bannedUids': FieldValue.arrayUnion([userId]),
      'publicMembers': FieldValue.arrayRemove([userId]),
      'members': FieldValue.arrayRemove([userId])
    });

    setState(() {
      // Remove the user from both public and members list
      publicUsers.removeWhere((user) => user.id == userId);
      members.removeWhere((user) => user.id == userId);
      bannedUsers.add(userId); // Add user to the banned list
    });
  }

  Future<void> _unbanUser(String userId) async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'bannedUids': FieldValue.arrayRemove([userId])
    });

    setState(() {
      bannedUsers.remove(userId); // Remove from banned list
    });
  }

  Future<void> _promoteToModerator(String userId) async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'moderators': FieldValue.arrayUnion([userId])
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User promoted to moderator')));
  }

  Future<void> _deleteGroup() async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).delete();
    Navigator.pop(context); // Go back to the previous page after deletion
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Admin - ${widget.groupName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Public Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: publicUsers.length,
              itemBuilder: (context, index) {
                var user = publicUsers[index];
                return ListTile(
                  title: Text(user['email'] ?? 'Unknown'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _addUserToMembers(user.id),
                        child: const Text('Add to\nMembers'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _banUser(user.id),
                        child: const Text('Ban\nUser'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                var user = members[index];
                return ListTile(
                  title: Text(user['email'] ?? 'Unknown'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _promoteToModerator(user.id),
                        child: const Text('Promote\n       to\nModerator'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _banUser(user.id),
                        child: const Text('Ban\nUser'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('Banned Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bannedUsers.length,
              itemBuilder: (context, index) {
                var userId = bannedUsers[index];
                return ListTile(
                  title: Text('User ID: $userId'),
                  trailing: ElevatedButton(
                    onPressed: () => _unbanUser(userId),
                    child: const Text('Unban\nUser'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Red color for delete button
                ),
                onPressed: _deleteGroup,
                child: const Text('Delete Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
