import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class CallPage extends StatefulWidget {
  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  String callId = '';

  // Search-related variables
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allUsers = [];
  List<DocumentSnapshot> _filteredUsers = [];
  String _searchQuery = '';

  Timer? _callTimeoutTimer;
  bool _callAccepted = false;

  @override
  void initState() {
    super.initState();
    initRenderers();
    _fetchAllUsers(); // Fetch all users from Firestore
    _listenForCalls(); // Listen for incoming calls
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.dispose();
    _searchController.dispose();
    _callTimeoutTimer?.cancel();
    super.dispose();
  }

  // Initialize video renderers
  void initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // Fetch all users from Firestore
  void _fetchAllUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    setState(() {
      _allUsers = snapshot.docs.where((doc) {
        // Exclude the current user from search results
        return doc['uid'] != _auth.currentUser!.uid;
      }).toList();
    });
  }

  // Filter users based on search query
  void _searchUsers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredUsers = _allUsers.where((userDoc) {
        String name = userDoc['displayName'] ?? '';
        return name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // Listen for incoming calls
  void _listenForCalls() {
    String currentUid = _auth.currentUser!.uid;
    _firestore
        .collection('calls')
        .where('receiverUid', isEqualTo: currentUid)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        if (doc['hasDialed'] == true &&
            doc['callAccepted'] == null &&
            doc['callRejected'] == null) {
          _showIncomingCallDialog(doc);
        }
      }
    });
  }

  // Show incoming call dialog
  void _showIncomingCallDialog(DocumentSnapshot callDoc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Incoming Call'),
        content: Text('You have an incoming call from ${callDoc['callerName']}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectCall(callDoc.id);
            },
            child: Text('Decline'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _answerCall(callDoc);
              _showVideoCallDialog(); // Open the video call dialog
            },
            child: Text('Accept'),
          ),
        ],
      ),
    );
  }

  // Show the video call dialog
  void _showVideoCallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog unless hung up
      builder: (context) => AlertDialog(
        title: Text('Video Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: _localRenderer.srcObject != null
                        ? RTCVideoView(_localRenderer, mirror: true)
                        : Center(child: Text("Local Video")),
                  ),
                  Expanded(
                    child: _remoteRenderer.srcObject != null
                        ? RTCVideoView(_remoteRenderer)
                        : Center(child: Text("Remote Video")),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _hangUp(); // Hang up the call
            },
            child: Text('Hang Up'),
          ),
        ],
      ),
    );
  }

  // Answer the call
  void _answerCall(DocumentSnapshot callDoc) async {
    await _createPeerConnection(isCaller: false, callDoc: callDoc);
    await _firestore.collection('calls').doc(callDoc.id).update({
      'callAccepted': true,
    });
  }

  // Reject the call
  void _rejectCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'callRejected': true,
    });
  }

  // Create peer connection for WebRTC
  Future<void> _createPeerConnection({
    required bool isCaller,
    String? receiverUid,
    DocumentSnapshot? callDoc,
  }) async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}, // STUN server
      ],
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'frameRate': 15,
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
    });

    for (var track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    setState(() {
      _localRenderer.srcObject = _localStream;
    });

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate != null) {
        String collectionName =
            isCaller ? 'callerCandidates' : 'receiverCandidates';
        _firestore
            .collection('calls')
            .doc(callId)
            .collection(collectionName)
            .add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    if (isCaller) {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      callId = _firestore.collection('calls').doc().id;
      await _firestore.collection('calls').doc(callId).set({
        'offer': offer.sdp,
        'callerUid': _auth.currentUser!.uid,
        'callerName': _auth.currentUser!.displayName ?? 'Caller',
        'receiverUid': receiverUid,
        'hasDialed': true,
        'callAccepted': null,
        'callRejected': null,
      });

      _callTimeoutTimer = Timer(Duration(seconds: 30), () async {
        if (!_callAccepted) {
          await _firestore.collection('calls').doc(callId).delete();
          _hangUp();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Call timed out')),
          );
        }
      });

      _firestore.collection('calls').doc(callId).snapshots().listen(
        (snapshot) async {
          if (snapshot.exists) {
            if (snapshot.data()!['callAccepted'] == true) {
              _callAccepted = true;
              _callTimeoutTimer?.cancel();
              if (snapshot.data()!['answer'] != null) {
                RTCSessionDescription answer = RTCSessionDescription(
                  snapshot.data()!['answer'],
                  'answer',
                );
                await _peerConnection!.setRemoteDescription(answer);
              }
              _showVideoCallDialog(); // Show the video call dialog when call is accepted
            } else if (snapshot.data()!['callRejected'] == true) {
              _callTimeoutTimer?.cancel();
              await _firestore.collection('calls').doc(callId).delete();
              _hangUp();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Call was declined')),
              );
            }
          }
        },
      );

      _firestore
          .collection('calls')
          .doc(callId)
          .collection('receiverCandidates')
          .snapshots()
          .listen((snapshot) {
        for (var doc in snapshot.docs) {
          var data = doc.data();
          RTCIceCandidate candidate = RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          );
          _peerConnection!.addCandidate(candidate);
        }
      });
    } else {
      callId = callDoc!.id;
      String offerSdp = callDoc['offer'];
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offerSdp, 'offer'),
      );

      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await _firestore.collection('calls').doc(callId).update({
        'answer': answer.sdp,
      });

      _firestore
          .collection('calls')
          .doc(callId)
          .collection('callerCandidates')
          .snapshots()
          .listen((snapshot) {
        for (var doc in snapshot.docs) {
          var data = doc.data();
          RTCIceCandidate candidate = RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          );
          _peerConnection!.addCandidate(candidate);
        }
      });
    }
  }

  // Hang up call
  void _hangUp() async {
    _peerConnection?.close();
    _peerConnection = null;
    _localStream?.dispose();
    setState(() {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    });

    if (callId.isNotEmpty) {
      await _firestore.collection('calls').doc(callId).delete();
    }
  }

  // Initiate call to the selected user
  void _initiateCall(String receiverUid) {
    _callAccepted = false;
    _createPeerConnection(isCaller: true, receiverUid: receiverUid);
    _showVideoCallDialog(); // Open the video call dialog when starting the call
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call Page'),
      ),
      body: Column(
        children: [
          // Search Bar for users
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by username',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchUsers,
            ),
          ),
          // Display search results
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(child: Text('Search for users to call'))
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      var userDoc = _filteredUsers[index];
                      String displayName =
                          userDoc['displayName'] ?? 'No Name';
                      String receiverUid = userDoc['uid'];
                      return ListTile(
                        leading: Icon(Icons.person),
                        title: Text(displayName),
                        trailing: IconButton(
                          icon: Icon(Icons.call),
                          onPressed: () => _initiateCall(receiverUid),
                        ),
                      );
                    },
                  ),
          ),
          // Video Views are handled in the dialog now
        ],
      ),
    );
  }
}
