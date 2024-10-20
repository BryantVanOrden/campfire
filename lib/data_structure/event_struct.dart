import 'package:campfire/data_structure/comment_struct.dart';

class Event {
  String eventId;
  String? imageLink;
  String creatorUid;
  String? groupId;
  bool isPublic;
  DateTime? dateTime;
  String? location;
  int likeCount;
  List<Comment>? comments; // New field to store comments

  Event({
    required this.eventId,
    this.imageLink,
    required this.creatorUid,
    this.groupId,
    required this.isPublic,
    this.dateTime,
    this.location,
    this.likeCount = 0,
    this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'imageLink': imageLink,
      'creatorUid': creatorUid,
      'groupId': groupId,
      'isPublic': isPublic,
      'dateTime': dateTime?.toIso8601String(),
      'location': location,
      'likeCount': likeCount,
      // Do not include comments in Firestore document to avoid large data
    };
  }

  static Event fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['eventId'],
      imageLink: json['imageLink'],
      creatorUid: json['creatorUid'],
      groupId: json['groupId'],
      isPublic: json['isPublic'],
      dateTime:
          json['dateTime'] != null ? DateTime.parse(json['dateTime']) : null,
      location: json['location'],
      likeCount: json['likeCount'] ?? 0,
      // Comments should be fetched separately
    );
  }
}
