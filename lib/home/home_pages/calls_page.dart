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

  // Dispose renderers when done
  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.dispose();
    super.dispose();
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

  // Create WebRTC offer and handle signaling
  Future<void> _makeCall(String receiverId) async {
    if (receiverId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot call yourself')),
      );
      return;
    }

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'} // Public STUN server
      ]
    });

    // Get local media stream (camera/microphone)
    MediaStream localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });

    // Display local video stream
    _localRenderer.srcObject = localStream;

    // Add local stream tracks to peer connection
    localStream.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, localStream);
    });

    // Handle remote stream
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0]; // Show remote video
        });
      }
    };

    // Listen for ICE candidates and send them to Firestore
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.userId)
          .collection('iceCandidates')
          .add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    // Create SDP offer
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Store the offer in Firestore
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.userId)
        .set({
      'offer': offer.sdp,
      'receiverId': receiverId,
    });

    // Listen for an answer from the remote peer
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
      var data = snapshot.data();
      if (data != null && data['answer'] != null) {
        _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['answer'], 'answer'));
      }
    });

    // Listen for ICE candidates from the receiver
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.userId)
        .collection('iceCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        var data = doc.data();
        _peerConnection!.addCandidate(RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        ));
      }
    });

    print("Initiating call from ${widget.userId} to $receiverId");
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
        _peerConnection = await createPeerConnection({
          'iceServers': [
            {'urls': 'stun:stun.l.google.com:19302'}
          ]
        });

        // Get local media stream
        MediaStream localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': {'facingMode': 'user'},
        });

        // Display local video stream
        _localRenderer.srcObject = localStream;

        // Add local stream tracks to peer connection
        localStream.getTracks().forEach((track) {
          _peerConnection?.addTrack(track, localStream);
        });

        // Handle remote stream
        _peerConnection?.onTrack = (RTCTrackEvent event) {
          if (event.streams.isNotEmpty) {
            setState(() {
              _remoteRenderer.srcObject = event.streams[0]; // Show remote video
            });
          }
        };

        // Set remote SDP offer
        await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['offer'], 'offer'));

        // Create SDP answer and send to Firestore
        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(widget.userId)
            .update({
          'answer': answer.sdp,
        });

        // Listen for ICE candidates
        FirebaseFirestore.instance
            .collection('calls')
            .doc(widget.userId)
            .collection('iceCandidates')
            .snapshots()
            .listen((snapshot) {
          for (var doc in snapshot.docs) {
            var data = doc.data();
            _peerConnection!.addCandidate(RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ));
          }
        });
      }
    });
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
        ],
      ),
    );
  }
}
