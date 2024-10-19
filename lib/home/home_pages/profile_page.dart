import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout(BuildContext context) async {
    await _auth.signOut();
    // Optionally, navigate to login page
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Information
          CircleAvatar(
            radius: 50,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : AssetImage('assets/default_profile.png') as ImageProvider,
          ),
          SizedBox(height: 20),
          Text(
            user?.email ?? 'No Email',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20),
          // Logout Button
          ElevatedButton(
            onPressed: () => _logout(context),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
