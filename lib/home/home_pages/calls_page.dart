import 'dart:async';

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

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  StreamSubscription<DocumentSnapshot>? _callSubscription;
  StreamSubscription<QuerySnapshot>? _iceCandidateSubscription;

  bool _inCall = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _fetchAvailableUsers();
    requestPermissions(); // Request permissions on page load
    _listenForIncomingCalls(); // Start listening for incoming calls
  }

  // Initialize video renderers
  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // Dispose renderers and close connections when done
  @override
  void dispose() {
    _cleanupCall();
    super.dispose();
  }

  // Cleanup function to end the call
  void _cleanupCall() {
    // Stop local stream tracks and dispose of the renderer
    _localRenderer.srcObject?.getTracks().forEach((track) {
      track.stop();
    });
    _localRenderer.srcObject = null;
    _localRenderer.dispose();

    // Stop remote stream tracks and dispose of the renderer
    _remoteRenderer.srcObject?.getTracks().forEach((track) {
      track.stop();
    });
    _remoteRenderer.srcObject = null;
    _remoteRenderer.dispose();

    // Close peer connection
    _peerConnection?.close();
    _peerConnection = null;

    // Cancel Firestore subscriptions
    _callSubscription?.cancel();
    _iceCandidateSubscription?.cancel();

    setState(() {
      _inCall = false;
    });
  }

  // Request camera and microphone permissions
  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (!statuses[Permission.camera]!.isGranted ||
        !statuses[Permission.microphone]!.isGranted) {
      print("Camera or microphone permissions denied");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please grant camera and microphone permissions')),
      );
      await openAppSettings();
    }
  }

  // Fetch users from Firestore
  Future<void> _fetchAvailableUsers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> fetchedUsers = snapshot.docs
        .map((doc) => {
              'displayName': doc['displayName'],
              'uid': doc['uid'],
              'email': doc['email'],
            })
        .toList();

    setState(() {
      users = fetchedUsers;
      filteredUsers = fetchedUsers;
    });
  }

  // Function to search users by displayName
  void _searchUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = users.where((userDoc) {
        String name = userDoc['displayName'] ?? '';
        return name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // Function to handle accepting a call
  Future<void> _acceptCall(String callerId) async {
    setState(() {
      _inCall = true;
    });
    // Handle the call acceptance logic here (connect WebRTC, etc.)
    // You can reuse the logic from `_listenForIncomingCalls`
  }

  // Function to end the current call
  void _endCall() {
    _cleanupCall();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call ended')),
    );
  }

  // Listen for incoming call offers and respond
  Future<void> _listenForIncomingCalls() async {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) async {
      var data = snapshot.data();
      if (data != null && data['offer'] != null) {
        // Show a dialog to accept or reject the call
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Incoming Call'),
            content: const Text('Do you want to accept the call?'),
            actions: [
              TextButton(
                child: const Text('Reject'),
                onPressed: () {
                  Navigator.pop(context); // Dismiss the dialog
                },
              ),
              TextButton(
                child: const Text('Accept'),
                onPressed: () {
                  Navigator.pop(context); // Dismiss the dialog
                  _acceptCall(data['callerId']);
                },
              ),
            ],
          ),
        );
      }
    });
  }

  // Create WebRTC offer and handle signaling
  Future<void> _makeCall(String receiverId) async {
    if (receiverId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot call yourself')),
      );
      return;
    }

    setState(() {
      _inCall = true;
    });

    // Call setup logic (similar to before) ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls Page'),
      ),
      body: Column(
        children: [
          // Search bar for searching users by displayName
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _searchUsers,
            ),
          ),
          // Display the list of filtered users
          Flexible(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                var user = filteredUsers[index];
                return ListTile(
                  title: Text(user['displayName']),
                  subtitle: Text("Email: ${user['email']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () {
                      _makeCall(user['uid']);
                    },
                  ),
                );
              },
            ),
          ),
          // Display local and remote video
          Flexible(
            child: Row(
              children: [
                Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
                Expanded(child: RTCVideoView(_remoteRenderer)),
              ],
            ),
          ),
          // Buttons to Accept/End Calls
          if (_inCall) ...[
            ElevatedButton(
              onPressed: _endCall,
              child: const Text('End Call'),
            ),
          ] else ...[
            const Text('No active call'),
          ],
        ],
      ),
    );
  }
}
