import 'package:campfire/screens/video_call_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallsPage extends StatefulWidget {
  @override
  _CallsPageState createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch users from Firestore
  Stream<List<UserData>> _fetchUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserData.fromDocument(doc);
      }).toList();
    });
  }

  void _startCall(String callerId, String receiverId) {
    // Generate a unique call ID (you can also use a UUID or similar)
    String callId = '${callerId}_$receiverId';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallPage(callId: callId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calls'),
      ),
      body: StreamBuilder<List<UserData>>(
        stream: _fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;
          final currentUserId = _auth.currentUser!.uid;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              if (user.id == currentUserId) {
                return SizedBox.shrink(); // Skip current user
              }

              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () => _startCall(currentUserId, user.id),
              );
            },
          );
        },
      ),
    );
  }
}

// Define a UserData class to handle user data
class UserData {
  final String id;
  final String name;
  final String email;

  UserData({required this.id, required this.name, required this.email});

  factory UserData.fromDocument(DocumentSnapshot doc) {
    return UserData(
      id: doc.id,
      name: doc['name'] ?? 'Unnamed',
      email: doc['email'] ?? 'No Email',
    );
  }
}
