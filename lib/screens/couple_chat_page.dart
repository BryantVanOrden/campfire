import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import 'list_of_games_page.dart';

class CoupleChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const CoupleChatPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  });

  @override
  _CoupleChatPageState createState() => _CoupleChatPageState();
}

class _CoupleChatPageState extends State<CoupleChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final TextEditingController _messageController = TextEditingController();

  late String currentUserId;
  late String chatId;
  bool _isRecording = false;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      currentUserId = currentUser.uid;
      chatId = _generateChatId(currentUserId, widget.otherUserId);
      _initializeRecorder();
      setState(() {});
    }
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    if (await Permission.microphone.request().isGranted) {
      // Microphone permission granted
    } else {
      // Handle permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Microphone permission is required to record audio')),
      );
    }
  }

  String _generateChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '$uid1-$uid2' : '$uid2-$uid1';
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    _messageController.clear();

    DatabaseReference chatRef = _database.ref().child('chats/$chatId');

    var messageData = {
      'senderId': currentUserId,
      'text': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    chatRef.push().set(messageData);
  }

  Future<void> _startRecording() async {
    final directory = await getTemporaryDirectory();
    _audioFilePath = '${directory.path}/audio_record.aac';

    await _recorder.startRecorder(
      toFile: _audioFilePath,
      codec: Codec.aacADTS,
    );
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });

    if (_audioFilePath != null) {
      _sendVoiceMessage(_audioFilePath!);
    }
  }

  Future<void> _sendVoiceMessage(String filePath) async {
    String fileName = 'voice_memo_${DateTime.now().millisecondsSinceEpoch}.aac';
    Reference ref =
        FirebaseStorage.instance.ref().child('voice_memos').child(fileName);

    UploadTask uploadTask = ref.putFile(File(filePath));
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    DatabaseReference chatRef = _database.ref().child('chats/$chatId');
    var messageData = {
      'senderId': currentUserId,
      'voiceMemo': downloadUrl, // Save the download URL instead of file path
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    chatRef.push().set(messageData);
  }

  Future<void> _playVoiceMemo(String url) async {
    await _player.startPlayer(
      fromURI: url,
      codec: Codec.aacADTS,
    );
  }

  void _openGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GamesPage(),
      ),
    );
  }

  Widget _buildMessageItem(Map<dynamic, dynamic> message) {
    bool isMe = message['senderId'] == currentUserId;
    if (message['voiceMemo'] != null) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _playVoiceMemo(message['voiceMemo']),
        ),
      );
    } else {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isMe ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message['text'] ?? '',
            style: TextStyle(color: isMe ? Colors.white : Colors.black),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    DatabaseReference chatRef = _database.ref().child('chats/$chatId');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserPhotoUrl != null &&
                      widget.otherUserPhotoUrl!.isNotEmpty
                  ? NetworkImage(widget.otherUserPhotoUrl!)
                  : const AssetImage('assets/images/default_profile_pic.jpg')
                      as ImageProvider,
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: chatRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> messagesMap =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  List<dynamic> messages = messagesMap.values.toList();

                  messages.sort((a, b) => a['timestamp'] - b['timestamp']);

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      Map<dynamic, dynamic> message =
                          messages[index] as Map<dynamic, dynamic>;
                      return _buildMessageItem(message);
                    },
                  );
                } else {
                  return const Center(child: Text('No messages yet.'));
                }
              },
            ),
          ),
          // Message Input and Buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Game Button
                IconButton(
                  icon: const Icon(Icons.sports_esports),
                  onPressed: _openGame,
                ),
                // Voice Memo Button
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                // Text Input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                // Send Button
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }
}
