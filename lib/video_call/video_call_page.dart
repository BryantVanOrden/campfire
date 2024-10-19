import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallPage extends StatefulWidget {
  final String receiverId;

  VideoCallPage({required this.receiverId});

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCall = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeRenderers();
    _getUserMedia();
    _createOffer();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _requestPermissions() async {
    // Request camera and microphone permissions
    var status = await Permission.camera.request();
    if (status.isDenied) {
      // The permission has been denied
      print('Camera permission denied');
    }

    status = await Permission.microphone.request();
    if (status.isDenied) {
      // The permission has been denied
      print('Microphone permission denied');
    }
  }

  // Get local media (video and audio)
  Future<void> _getUserMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });
    _localRenderer.srcObject = _localStream;
  }

  // Create a new call and send offer to the receiver
  Future<void> _createOffer() async {
    _peerConnection = await _createPeerConnection();
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Save the offer to Firestore for the receiver
    var callId = _auth.currentUser!.uid;
    await _firestore.collection('calls').doc(callId).set({
      'offer': offer.toMap(),
      'callerId': _auth.currentUser!.uid,
      'receiverId': widget.receiverId,
    });

    // Listen for answer
    _firestore
        .collection('calls')
        .doc(callId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.data()!['answer'] != null) {
        var answer = snapshot.data()!['answer'];
        await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(answer['sdp'], answer['type']));
      }
    });
  }

  // Peer connection setup
  Future<RTCPeerConnection> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);

    pc.onIceCandidate = (candidate) {
      // Send ICE candidates to Firestore
      _firestore.collection('calls').doc(_auth.currentUser!.uid).update({
        'callerCandidates': FieldValue.arrayUnion([candidate.toMap()]),
      });
    };

    pc.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    return pc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call with ${widget.receiverId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(_localRenderer),
          ),
          Expanded(
            child: RTCVideoView(_remoteRenderer),
          ),
        ],
      ),
    );
  }
}
