import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class CallsPage extends StatefulWidget {
  final String userId;

  const CallsPage({required this.userId, Key? key}) : super(key: key);

  @override
  _CallsPageState createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAvailableUsers();
    requestPermissions(); // Request permissions on page load
  }

  // Request camera and microphone permissions
  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    // Handle the case where permissions are denied
    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      print("Camera and microphone permissions granted");
    } else {
      print("Camera or microphone permissions denied");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please grant camera and microphone permissions')),
      );
      // Optionally, open the app settings to guide the user
      openAppSettings();
    }
  }

  // Fetch users from Firestore
  Future<void> _fetchAvailableUsers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> fetchedUsers = snapshot.docs
        .map((doc) => {
              'displayName':
                  doc['displayName'], // Ensure Firestore has 'displayName'
              'uid': doc['uid'], // Fetch 'uid'
              'email': doc['email'], // Fetch 'email' if needed
              'dateOfBirth': doc['dateOfBirth'], // Optional: dateOfBirth
              'location': doc['location'], // Optional: location details
            })
        .toList();

    setState(() {
      users = fetchedUsers; // Store all users
      filteredUsers = fetchedUsers; // Initially, show all users
    });
  }

  // Function to search users by displayName
  void _searchUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = users.where((userDoc) {
        String name = userDoc['displayName'] ?? ''; // Handle null displayName
        return name
            .toLowerCase()
            .contains(query.toLowerCase()); // Perform case-insensitive search
      }).toList();
    });
  }

  // Initiate a call by creating an offer (placeholder)
  Future<void> _makeCall(String receiverId) async {
    // Prevent the user from calling themselves
    if (receiverId == widget.userId) {
      print("Cannot initiate a call to yourself");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot call yourself')),
      );
      return;
    }

    // Proceed with the call if receiverId is different from userId
    print("Initiating call from ${widget.userId} to $receiverId");
    // Example WebRTC or Firebase call logic here...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calls Page'),
      ),
      body: Column(
        children: [
          // Search bar for searching users by displayName
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged:
                  _searchUsers, // Call the search function on input change
            ),
          ),
          // Display the list of filtered users
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                var user = filteredUsers[index];
                return ListTile(
                  title: Text(user['displayName']), // Display user displayName
                  subtitle: Text(
                      "Email: ${user['email']}"), // Optionally show the email
                  trailing: IconButton(
                    icon: Icon(Icons.call),
                    onPressed: () {
                      _makeCall(user['uid']); // Use 'uid' to initiate call
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
