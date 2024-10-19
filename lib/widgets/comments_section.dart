// comments_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsSection extends StatefulWidget {
  final String eventId;

  const CommentsSection({Key? key, required this.eventId}) : super(key: key);

  @override
  _CommentsSectionState createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late Stream<QuerySnapshot> _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = _firestore
        .collection('events')
        .doc(widget.eventId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

Future<void> _addComment() async {
  String commentText = _commentController.text.trim();
  if (commentText.isEmpty || _currentUser == null) return;

  try {
    // Fetch user's data from Firebase
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();

    if (!userDoc.exists) {
      print('User document does not exist.');
      return;
    }

    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null) {
      print('User data is null.');
      return;
    }

    // Handle missing displayName and profileImageLink
    String userName = userData['displayName'] ?? 'Anonymous';  // Use default 'Anonymous' if displayName is missing
    String? profileImageLink = userData['profileImageLink'];   // This will be null if profileImageLink doesn't exist

    DocumentReference commentRef = _firestore
        .collection('events')
        .doc(widget.eventId)
        .collection('comments')
        .doc();

    // Add comment to Firestore
    await commentRef.set({
      'commentId': commentRef.id,
      'userId': _currentUser!.uid,
      'userName': userName,
      'userProfileImageUrl': profileImageLink, // This can be null
      'content': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();  // Clear the text input after adding comment
  } catch (e) {
    print('Error adding comment: $e');
    // Optionally, show a snackbar or alert to the user
  }
}


  String _timeAgo(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display comments
        StreamBuilder<QuerySnapshot>(
          stream: _commentsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container();
            List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var commentData = docs[index].data() as Map<String, dynamic>;
                String userName = commentData['userName'] ?? 'Anonymous';
                String content = commentData['content'] ?? '';
                String? userProfileImageUrl =
                    commentData['userProfileImageUrl'];
                Timestamp timestamp =
                    commentData['timestamp'] ?? Timestamp.now();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userProfileImageUrl != null
                        ? NetworkImage(userProfileImageUrl)
                        : null,
                    child: userProfileImageUrl == null
                        ? Text(
                            userName[0],
                            style: TextStyle(color: Colors.white),
                          )
                        : null,
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  title: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$userName  ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        TextSpan(
                          text: content,
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Text(
                    _timeAgo(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                );
              },
            );
          },
        ),
        Divider(),
        // Input field to add new comment
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.grey[200],
                  filled: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: _addComment,
            ),
          ],
        ),
      ],
    );
  }
}
