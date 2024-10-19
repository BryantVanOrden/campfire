import 'package:campfire/screens/group_chat_admin_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({super.key, required this.groupId, required this.groupName});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TabController? _tabController;
  bool isMember = false;
  bool isModerator = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserStatus(); // Check if the user is a member or moderator
  }

  Future<void> _checkUserStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      if (groupDoc.exists) {
        List<String> members = List<String>.from(groupDoc['members'] ?? []);
        List<String> moderators =
            List<String>.from(groupDoc['moderators'] ?? []);

        setState(() {
          isMember = members.contains(user.uid);
          isModerator = moderators.contains(user.uid);
        });
      }
    }
  }

  Future<void> _sendMessage(String chatType) async {
    if (_messageController.text.isNotEmpty) {
      User? user = _auth.currentUser;
      if (user != null) {
        String collection =
            chatType == 'public' ? 'publicMessages' : 'messages';
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection(collection)
            .add({
          'text': _messageController.text,
          'senderId': user.uid,
          'senderEmail': user.email ?? 'Unknown',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'message',
        });

        if (chatType == 'public' && !isMember) {
          // Add user to the publicMembers list if not a member
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .update({
            'publicMembers': FieldValue.arrayUnion([user.uid])
          });
        }

        _messageController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Public'),
          ],
        ),
        actions: [
          if (isModerator)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to the group chat admin page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupChatAdminPage(
                      groupId: widget.groupId,
                      groupName: widget.groupName,
                    ),
                  ),
                );
              },
            )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Members Chat
          isMember ? _buildChat('members') : _buildRestrictedAccessMessage(),

          // Public Chat
          _buildChat('public'),
        ],
      ),
    );
  }

  Widget _buildChat(String chatType) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .collection(
                    chatType == 'public' ? 'publicMessages' : 'messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var messages = snapshot.data!.docs;

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  return _buildMessageItem(message);
                },
              );
            },
          ),
        ),
        // Input for sending messages
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your message...',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _sendMessage(chatType),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestrictedAccessMessage() {
    return const Center(
      child: Text('Members-only chat. Join the group to participate.'),
    );
  }

  Widget _buildMessageItem(DocumentSnapshot message) {
    Map<String, dynamic> messageData = message.data() as Map<String, dynamic>;
    String type = messageData['type'] ?? 'message';
    String senderEmail = messageData.containsKey('senderEmail')
        ? messageData['senderEmail']
        : 'Unknown';
    String text =
        messageData.containsKey('text') ? messageData['text'] : 'No Content';

    if (type == 'message') {
      return ListTile(
        title: Text(senderEmail),
        subtitle: Text(text),
      );
    } else if (type == 'event') {
      String? eventImageUrl =
          messageData.containsKey('imageUrl') ? messageData['imageUrl'] : null;
      String? eventLocation =
          messageData.containsKey('location') ? messageData['location'] : null;
      DateTime? eventDateTime = messageData.containsKey('dateTime')
          ? (messageData['dateTime'] as Timestamp).toDate()
          : null;

      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (eventImageUrl != null)
                Image.network(
                  eventImageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey,
                  child: const Icon(Icons.event),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style:
                          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (eventLocation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Location: $eventLocation'),
                      ),
                    if (eventDateTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                            'Date: ${eventDateTime.toLocal().toString().split(' ')[0]}'),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('By $senderEmail'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
