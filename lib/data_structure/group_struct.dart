class Group {
  String groupId;
  String name;
  List<String> members; // List of user UIDs in the private group
  List<String> moderators; // List of user UIDs with admin access
  List<String> publicMembers; // List of UIDs in the public chat
  List<String> bannedUids; // List of UIDs banned from the group

  Group({
    required this.groupId,
    required this.name,
    required this.members,
    required this.moderators,
    required this.publicMembers,
    required this.bannedUids,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'name': name,
      'members': members,
      'moderators': moderators,
      'publicMembers': publicMembers,
      'bannedUids': bannedUids,
    };
  }

  static Group fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['groupId'],
      name: json['name'],
      members: List<String>.from(json['members']),
      moderators: List<String>.from(json['moderators']),
      publicMembers: List<String>.from(json['publicMembers']),
      bannedUids: List<String>.from(json['bannedUids']),
    );
  }
}
