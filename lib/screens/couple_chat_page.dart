import 'package:campfire/screens/paintball_game_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CoupleChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const CoupleChatPage({super.key, 
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
  final TextEditingController _messageController = TextEditingController();

  late String currentUserId;
  late String chatId;

  @override
  void initState() {
    super.initState();
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      currentUserId = currentUser.uid;
      // Generate a consistent chat ID based on user IDs
      chatId = _generateChatId(currentUserId, widget.otherUserId);
      setState(() {});
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

  void _openGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaintballGamePage(
          chatId: chatId,
          currentUserId: currentUserId,
          otherUserId: widget.otherUserId,
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<dynamic, dynamic> message) {
    bool isMe = message['senderId'] == currentUserId;
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

  @override
  Widget build(BuildContext context) {
    DatabaseReference chatRef = _database.ref().child('chats/$chatId');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserPhotoUrl != null && widget.otherUserPhotoUrl!.isNotEmpty
                  ? NetworkImage(widget.otherUserPhotoUrl!)
                  : const AssetImage('assets/images/default_profile_pic.jpg') as ImageProvider,
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

                  // Convert messages to a List<dynamic>
                  List<dynamic> messages = messagesMap.values.toList();

                  // Sort messages by timestamp
                  messages.sort((a, b) => a['timestamp'] - b['timestamp']);

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // Cast each message to Map<dynamic, dynamic>
                      Map<dynamic, dynamic> message = messages[index] as Map<dynamic, dynamic>;
                      return _buildMessageItem(message);
                    },
                  );
                } else {
                  return const Center(child: Text('No messages yet.'));
                }
              },
            ),
          ),
          // Message Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Game Button
                IconButton(
                  icon: const Icon(Icons.sports_esports),
                  onPressed: _openGame,
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
}
