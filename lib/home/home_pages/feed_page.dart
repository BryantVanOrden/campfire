import 'package:campfire/screens/group_chat_page.dart';
import 'package:campfire/shared_widets/create_event_page.dart';
import 'package:campfire/theme/app_colors.dart';
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
                  groupId: groupId,
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
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image with rounded top corners
            if (eventImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  eventImageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              // Placeholder image if eventImageUrl is null
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.event,
                    size: 100,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

            // Event Details
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  Text(
                    eventName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),

                  // Small spacing after the event name
                  SizedBox(height: 4),

                  // Event Description
                  Text(
                    eventDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGreen,
                    ),
                  ),

                  // Variable spacing before the location
                  SizedBox(height: 12),

                  // Location (if available)
                  if (location != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.mediumGreen,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mediumGreen,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Adjusted spacing
                  if (location != null) SizedBox(height: 8),

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
                          return Row(
                            children: [
                              Icon(
                                Icons.group,
                                color: AppColors.lightGrey,
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                snapshot.data!['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.lightGrey,
                                ),
                              ),
                            ],
                          );
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
    );
  }
}