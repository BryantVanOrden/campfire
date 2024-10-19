class Group {
  String groupId;
  String name;
  List<String> members; // List of user UIDs in the private group
  List<String> moderators; // List of user UIDs with admin access
  List<String> publicMembers; // List of UIDs in the public chat
  List<String> bannedUids; // List of UIDs banned from the group
  String? imageUrl; // Nullable image URL for the group's picture

  Group({
    required this.groupId,
    required this.name,
    required this.members,
    required this.moderators,
    required this.publicMembers,
    required this.bannedUids,
    this.imageUrl, // Image URL can be null if no image is provided
  });

  // Convert the Group object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'name': name,
      'members': members,
      'moderators': moderators,
      'publicMembers': publicMembers,
      'bannedUids': bannedUids,
      'imageUrl': imageUrl, // Include imageUrl in JSON
    };
  }

  // Create a Group object from JSON
  static Group fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['groupId'],
      name: json['name'],
      members: List<String>.from(json['members']),
      moderators: List<String>.from(json['moderators']),
      publicMembers: List<String>.from(json['publicMembers']),
      bannedUids: List<String>.from(json['bannedUids']),
      imageUrl: json['imageUrl'], // Get the imageUrl from JSON if it exists
    );
  }
}
