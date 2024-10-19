import 'package:campfire/screens/group_chat_page.dart';
import 'package:campfire/theme/app_colors.dart';
import 'package:campfire/widgets/comments_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campfire/screens/group_chat_page.dart';
import 'package:campfire/theme/app_colors.dart';

class EventCard extends StatelessWidget {
  final DocumentSnapshot event;
  final List<String> userGroupIds;

  const EventCard({
    Key? key,
    required this.event,
    required this.userGroupIds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String eventName = event['name'] ?? 'No Name';
    String eventDescription = event['description'] ?? 'No Description';
    String? eventImageUrl = event['imageLink'];
    String? location = event['location'];
    String? groupId = event['groupId'];

    // Check if event.data() is not null and if 'likeCount' exists, otherwise default to 0
    Map<String, dynamic>? eventData =
        event.data() as Map<String, dynamic>?; // Safely cast
    int likeCount = (eventData != null && eventData.containsKey('likeCount'))
        ? (eventData['likeCount'] as int? ?? 0)
        : 0;

    bool isPublic = event['isPublic'] ?? true; // Default to true if isPublic is null

    bool canShowEvent =
        isPublic || (groupId != null && userGroupIds.contains(groupId));

    if (!canShowEvent)
      return SizedBox.shrink(); // Skip if user can't see this event

    return InkWell(
      onTap: () async {
        if (groupId != null) {
          DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .get();

          if (groupSnapshot.exists) {
            String groupName = groupSnapshot['name'] ?? 'Unknown Group';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    eventDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  SizedBox(height: 12),
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
                  if (location != null) SizedBox(height: 8),
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
                        return SizedBox.shrink();
                      },
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.thumb_up),
                        onPressed: () {
                          // Increment like count in Firestore
                          FirebaseFirestore.instance
                              .collection('events')
                              .doc(event.id)
                              .update({'likeCount': FieldValue.increment(1)});
                        },
                      ),
                      Text('$likeCount'),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CommentsSection(eventId: event.id),
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
