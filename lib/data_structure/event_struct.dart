class Event {
  String eventId;
  String? imageLink; // Nullable image link stored in Firebase
  String creatorUid;
  String? groupId; // Nullable group ID
  bool isPublic;
  DateTime? dateTime; // Nullable time and date
  String? location;  // Nullable location

  Event({
    required this.eventId,
    this.imageLink,
    required this.creatorUid,
    this.groupId,
    required this.isPublic,
    this.dateTime,
    this.location,
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
    };
  }

  static Event fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['eventId'],
      imageLink: json['imageLink'],
      creatorUid: json['creatorUid'],
      groupId: json['groupId'],
      isPublic: json['isPublic'],
      dateTime: json['dateTime'] != null ? DateTime.parse(json['dateTime']) : null,
      location: json['location'],
    );
  }
}
