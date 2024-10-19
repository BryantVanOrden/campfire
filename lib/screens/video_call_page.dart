import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoCallPage extends StatefulWidget {
  final String callId; // Unique identifier for the call

  VideoCallPage({required this.callId});

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    _initializeRenderers();
    _startCall();
  }

  void _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _startCall() async {
    // Get user media
    _localStream = await _getUserMedia();
    _localRenderer.srcObject = _localStream;

    // Create peer connection
    _peerConnection = await _createPeerConnection();

    // Add local stream tracks
    _localStream.getTracks().forEach((track) {
      _peerConnection.addTrack(track, _localStream);
    });

    // Handle ICE candidates
    _peerConnection.onIceCandidate = (candidate) {
      if (candidate != null) {
        _firestore
            .collection('calls')
            .doc(widget.callId)
            .collection('candidates')
            .add(candidate.toMap());
      }
    };

    // Handle remote stream
    _peerConnection.onTrack = (event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    // Offer or answer based on whether the caller is the initiator
    var callDoc = _firestore.collection('calls').doc(widget.callId);
    var offerSnapshot = await callDoc.get();

    if (!offerSnapshot.exists) {
      // Create an offer if it doesn't exist
      var offer = await _peerConnection.createOffer();
      await _peerConnection.setLocalDescription(offer);
      await callDoc.set({'offer': offer.toMap()});
    } else {
      // Handle answer scenario
      var data = offerSnapshot.data()!;
      if (data['offer'] != null) {
        var offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
        await _peerConnection.setRemoteDescription(offer);

        var answer = await _peerConnection.createAnswer();
        await _peerConnection.setLocalDescription(answer);
        await callDoc.update({'answer': answer.toMap()});
      }
    }

    // Listen for ICE candidates from the other user
    _firestore
        .collection('calls')
        .doc(widget.callId)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          var candidate = RTCIceCandidate(
            doc.doc.data()!['candidate'],
            doc.doc.data()!['sdpMid'],
            doc.doc.data()!['sdpMLineIndex'],
          );
          _peerConnection.addIceCandidate(candidate);
        }
      }
    });

    // Handle remote answer
    callDoc.snapshots().listen((snapshot) async {
      var data = snapshot.data();
      if (data != null && data['answer'] != null) {
        var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
        await _peerConnection.setRemoteDescription(answer);
      }
    });
  }

  Future<MediaStream> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };
    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
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

    var pc = await createPeerConnection(configuration, offerSdpConstraints);
    return pc;
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Call')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: RTCVideoView(_localRenderer),
            ),
            Expanded(
              child: RTCVideoView(_remoteRenderer),
            ),
          ],
        ),
      ),
    );
  }
}
