import 'package:campfire/shared_widets/edit_event_page.dart';
import 'package:campfire/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:campfire/data_structure/user_struct.dart' as cust;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  User? firebaseUser;
  cust.User? customUser;
  List<String> moderatorGroupIds = [];

  @override
  void initState() {
    super.initState();
    firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _loadCustomUserData(); // Fetch custom user data
      _loadModeratorGroups(); // Load moderator groups for the custom user
    }
  }

  // Fetch the custom user data from Firestore
  Future<void> _loadCustomUserData() async {
    if (firebaseUser != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(firebaseUser!.uid).get();

      setState(() {
        customUser =
            cust.User.fromJson(userSnapshot.data() as Map<String, dynamic>);
      });
    }
  }

  // Load groups where the current custom user is a moderator
  Future<void> _loadModeratorGroups() async {
    if (customUser != null) {
      QuerySnapshot groupSnapshot = await _firestore
          .collection('groups')
          .where('moderators', arrayContains: customUser!.uid)
          .get();

      setState(() {
        moderatorGroupIds = groupSnapshot.docs.map((doc) => doc.id).toList();
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
              customUser?.profileImageLink != null
                  ? Image.network(customUser!.profileImageLink!)
                  : Image.asset('assets/images/default_profile_pic.jpg'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      _pickNewProfilePicture(); // Open image picker
                    },
                    child: const Text('Pick New Picture'),
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

    if (image != null && firebaseUser != null) {
      // Upload the image to Firebase Storage
      String downloadUrl = await _uploadProfilePicture(File(image.path));

      // Update the profileImageLink in Firestore for the custom user
      await _firestore.collection('users').doc(firebaseUser!.uid).update({
        'profileImageLink': downloadUrl,
      });

      // Refresh the custom user data
      _loadCustomUserData();
    }
  }

  // Function to upload profile picture to Firebase Storage
  Future<String> _uploadProfilePicture(File file) async {
    try {
      String fileName = 'profile_pictures/${firebaseUser?.uid}.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL(); // Get the image URL
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Function to log out the user
  void _logout(BuildContext context) async {
    await _auth.signOut();
    // Navigator.pushReplacementNamed(context, '/login');
  }

  // Fetch all events from groups where the custom user is a moderator
  Stream<QuerySnapshot> _getModeratorGroupEvents() {
    if (moderatorGroupIds.isEmpty) {
      return const Stream.empty();
    }
    return _firestore
        .collection('events')
        .where('groupId', whereIn: moderatorGroupIds)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme(); // Toggle between light and dark mode
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: customUser == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showFullScreenProfilePicture(context),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: customUser?.profileImageLink != null
                          ? NetworkImage(customUser!.profileImageLink!)
                          : const AssetImage(
                                  'assets/images/default_profile_pic.jpg')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    customUser?.displayName ?? 'No DisplayName',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    customUser?.email ?? 'No Email',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    child: const Text('Log out'),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Moderated Group Events',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _getModeratorGroupEvents(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      var events = snapshot.data!.docs;
                      if (events.isEmpty) {
                        return const Text('No events available.');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          var event = events[index];
                          return ListTile(
                            title: Text(event['name'] ?? 'No Name'),
                            subtitle:
                                Text(event['description'] ?? 'No Description'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditEventPage(event: event),
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
