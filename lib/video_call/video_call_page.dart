import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CallManager {
  RTCPeerConnection? _peerConnection;

  // Define the local and remote video renderers
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize the renderers
  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // Getters to access the renderers from outside the class
  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  // Creates a peer connection and adds the local media stream
  Future<void> initializePeerConnection() async {
    Map<String, dynamic> config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    Map<String, dynamic> constraints = {
      "mandatory": {},
      "optional": [],
    };

    _peerConnection = await createPeerConnection(config, constraints);

    // Get local media stream (audio/video)
    MediaStream localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });

    _localRenderer.srcObject =
        localStream; // Attach the stream to the local renderer

    localStream.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, localStream);
    });

    // Handle the remote stream
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      _remoteRenderer.srcObject =
          event.streams[0]; // Attach the remote stream to the remote renderer
    };

    // Handle ICE candidate generation
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      sendIceCandidateToFirestore(candidate);
    };
  }

  // Send ICE candidate to Firestore
  Future<void> sendIceCandidateToFirestore(RTCIceCandidate candidate) async {
    await _firestore
        .collection('calls')
        .doc('callerId')
        .collection('iceCandidates')
        .add({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  // Listen for ICE candidates from Firestore
  void listenForIceCandidates(String callerId) {
    _firestore
        .collection('calls')
        .doc(callerId)
        .collection('iceCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        _peerConnection!.addCandidate(
          RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ),
        );
      }
    });
  }

  // Send an SDP offer
  Future<void> createOffer(String callerId, String receiverId) async {
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await _firestore.collection('calls').doc(callerId).set({
      'offer': offer.sdp,
      'receiverId': receiverId,
    });
  }

  // Receive SDP answer
  Future<void> receiveAnswer(String callerId) async {
    DocumentSnapshot offerSnapshot =
        await _firestore.collection('calls').doc(callerId).get();

    if (offerSnapshot.exists) {
      var data = offerSnapshot.data() as Map<String, dynamic>;
      RTCSessionDescription answer =
          RTCSessionDescription(data['answer'], 'answer');
      await _peerConnection!.setRemoteDescription(answer);
    }
  }
}
