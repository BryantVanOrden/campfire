import 'package:campfire/screens/group_chat_page.dart';
import 'package:campfire/shared_widets/create_event_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String>? userGroupIds = [];

  @override
  void initState() {
    super.initState();
    _loadUserGroupIds(); // Fetch user groupIds at initialization
  }

  Future<void> _loadUserGroupIds() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          userGroupIds = List<String>.from(userDoc['groupIds'] ?? []);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateEventPage()),
              );
            },
          ),
        ],
      ),
      body: userGroupIds == null || userGroupIds!.isEmpty
          ? Center(child: CircularProgressIndicator()) // Wait until groupIds are loaded
          : StreamBuilder(
              stream: _firestore.collection('events').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No events to show.'));
                }

                List<DocumentSnapshot> events = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    var event = events[index];
                    bool isPublic = event['isPublic'] ?? false;
                    String? groupId = event['groupId'];

                    bool canShowEvent = isPublic || (groupId != null && userGroupIds!.contains(groupId));

                    if (!canShowEvent) return SizedBox.shrink(); // Skip if user can't see this event

                    return EventTile(event: event);
                  },
                );
              },
            ),
    );
  }
}

class EventTile extends StatelessWidget {
  final DocumentSnapshot event;

  const EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    String eventName = event['name'] ?? 'No Name';
    String eventDescription = event['description'] ?? 'No Description';
    String? eventImageUrl = event['imageLink'];
    String? location = event['location'];
    String? groupId = event['groupId'];
    DateTime? dateTime = event['dateTime'] != null
        ? (event['dateTime'] as Timestamp).toDate()
        : null;

    return InkWell(
      onTap: () async {
        if (groupId != null) {
          // Fetch the group details to get the group name
          DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .get();

          if (groupSnapshot.exists) {
            String groupName = groupSnapshot['name'] ?? 'Unknown Group';

            // Navigate to the GroupChatPage with groupId and groupName
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatPage(
                  groupId: groupId!,
                  groupName: groupName,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Group not found')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group ID is missing')),
          );
        }
      },
      child: Card(
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Event Image
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
                  child: Icon(Icons.event),
                ),

              SizedBox(width: 16),

              // Event Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name
                    Text(
                      eventName,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    // Event Description
                    Text(
                      eventDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Location (if available)
                    if (location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Location: $location'),
                      ),

                    // Date and Time (if available)
                    if (dateTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                            'Date: ${dateTime.toLocal().toString().split(' ')[0]}'),
                      ),

                    // Group Name (if available)
                    if (groupId != null)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('groups')
                            .doc(groupId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done &&
                              snapshot.data?.exists == true) {
                            return Text('Group: ${snapshot.data!['name']}');
                          }
                          return SizedBox.shrink(); // Don't show anything while loading
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}