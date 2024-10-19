// lib/home/home_pages/feed_page.dart
import 'package:campfire/shared_widets/create_event_page.dart';
import 'package:campfire/widgets/event_card.dart';
import 'package:campfire/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campfire/providers/feed_provider.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key); // Mark constructor as const

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
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
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          if (feedProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (feedProvider.events.isEmpty) {
            return Center(child: Text('No events to show.'));
          }

          return ListView.builder(
            itemCount: feedProvider.events.length,
            itemBuilder: (context, index) {
              var event = feedProvider.events[index];
              return EventCard(
                event: event,
                userGroupIds: feedProvider.userGroupIds,
              );
            },
          );
        },
      ),
    );
  }
}
