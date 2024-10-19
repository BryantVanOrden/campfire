import 'package:campfire/shared_widets/edit_event_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  User? user;
  List<String> moderatorGroupIds = [];

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadModeratorGroups(); // Load the groups where the user is a moderator
  }

  // Load groups where the current user is a moderator
  Future<void> _loadModeratorGroups() async {
    if (user != null) {
      // Fetch groups where the current user is listed as a moderator
      QuerySnapshot groupSnapshot = await _firestore
          .collection('groups')
          .where('moderators', arrayContains: user!.uid)
          .get();

      setState(() {
        // Store the group IDs where the user is a moderator
        moderatorGroupIds =
            groupSnapshot.docs.map((doc) => doc.id).toList();
      });
    }
  }

  // Function to show the full-screen profile picture
  void _showFullScreenProfilePicture(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display current profile picture in full screen
              user?.photoURL != null
                  ? Image.network(user!.photoURL!)
                  : Image.asset('assets/images/default_profile_pic.jpg'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      _pickNewProfilePicture(); // Open image picker
                    },
                    child: Text('Pick New Picture'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // Function to pick a new profile picture from the device
  Future<void> _pickNewProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Upload the image to Firebase Storage
      String downloadUrl = await _uploadProfilePicture(File(image.path));

      // Update the user's profile with the new picture URL
      await user?.updatePhotoURL(downloadUrl);

      // Refresh the UI to display the new picture
      setState(() {
        user = _auth.currentUser; // Refresh user data
      });
    }
  }

  // Function to upload profile picture to Firebase Storage
  Future<String> _uploadProfilePicture(File file) async {
    try {
      String fileName = 'profile_pictures/${user?.uid}.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL(); // Get the image URL
    } catch (e) {
      print('Error uploading profile picture: $e');
      throw e;
    }
  }

  // Function to log out the user
  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Fetch all events from groups where the user is a moderator
  Stream<QuerySnapshot> _getModeratorGroupEvents() {
    if (moderatorGroupIds.isEmpty) {
      return Stream.empty();
    }
    return _firestore
        .collection('events')
        .where('groupId', whereIn: moderatorGroupIds)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tap the profile picture to view and change it
            GestureDetector(
              onTap: () => _showFullScreenProfilePicture(context),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : AssetImage('assets/images/default_profile_pic.jpg')
                        as ImageProvider,
              ),
            ),
            SizedBox(height: 20),
            // Display user email
            Text(
              user?.email ?? 'No Email',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            // Logout button
            ElevatedButton(
              onPressed: () => _logout(context),
              child: Text('Logout'),
            ),
            SizedBox(height: 30),
            // Display the user's created events
            Text(
              'Moderated Group Events',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _getModeratorGroupEvents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var events = snapshot.data!.docs;
                if (events.isEmpty) {
                  return Text('No events available.');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    var event = events[index];
                    return ListTile(
                      title: Text(event['name'] ?? 'No Name'),
                      subtitle: Text(event['description'] ?? 'No Description'),
                      onTap: () {
                        // Navigate to the EditEventPage when tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditEventPage(event: event),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
