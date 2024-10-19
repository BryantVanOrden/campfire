import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

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

    String callId = widget.userId + '_' + receiverId;

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'} // Public STUN server
      ],
      'sdpSemantics': 'unified-plan',
    });

    // Monitor ICE connection state
    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE Connection State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateCompleted ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        print("ICE connection completed or disconnected");
        // Handle reconnection logic or inform the user
      }
    };

    // Get local media stream with adjusted constraints
    MediaStream localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'maxWidth': '640',
          'maxHeight': '480',
          'minFrameRate': '15',
          'maxFrameRate': '30',
        },
        'facingMode': 'user',
      },
    });

    _localRenderer.srcObject = localStream;

    localStream.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, localStream);
    });

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams.first;
        });
      }
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .collection('iceCandidates')
          .add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await FirebaseFirestore.instance.collection('calls').doc(callId).set({
      'offer': offer.sdp,
      'receiverId': receiverId,
    });

    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .snapshots()
        .listen((snapshot) {
      var data = snapshot.data();
      if (data != null && data['answer'] != null) {
        _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['answer'], 'answer'));
      }
    });

    _iceCandidateSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
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
        String callId = widget.userId + '_' + data['receiverId'];

        _peerConnection = await createPeerConnection({
          'iceServers': [
            {'urls': 'stun:stun.l.google.com:19302'}
          ],
          'sdpSemantics': 'unified-plan',
        });

        MediaStream localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': {
            'mandatory': {
              'minWidth': '640',
              'minHeight': '480',
              'maxWidth': '640',
              'maxHeight': '480',
              'minFrameRate': '15',
              'maxFrameRate': '30',
            },
            'facingMode': 'user',
          },
        });

        _localRenderer.srcObject = localStream;

        localStream.getTracks().forEach((track) {
          _peerConnection?.addTrack(track, localStream);
        });

        _peerConnection?.onTrack = (RTCTrackEvent event) {
          if (event.track.kind == 'video' && event.streams.isNotEmpty) {
            setState(() {
              _remoteRenderer.srcObject = event.streams.first;
            });
          }
        };

        await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['offer'], 'offer'));

        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(callId)
            .update({
          'answer': answer.sdp,
        });

        _iceCandidateSubscription = FirebaseFirestore.instance
            .collection('calls')
            .doc(callId)
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
