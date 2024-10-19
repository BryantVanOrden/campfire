import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campfire/video_call/video_call_page.dart';

class CallsPage extends StatefulWidget {
  @override
  _CallsPageState createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Calls'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No users available for calling'));
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];

              // Don't show the current user in the list
              if (user['uid'] == _auth.currentUser!.uid) {
                return SizedBox.shrink();
              }

              return ListTile(
                leading: Icon(Icons.video_call),
                title: Text(user['email'] ?? 'User'),
                subtitle: Text(user['email'] ?? 'No email'),
                onTap: () {
                  _startVideoCall(user['uid']);
                },
              );
            },
          );
        },
      ),
    );
  }

  // Function to start a video call
  void _startVideoCall(String receiverId) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallPage(receiverId: receiverId),
      ),
    );
  }
}
