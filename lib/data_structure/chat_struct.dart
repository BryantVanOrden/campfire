import 'package:campfire/data_structure/event_struct.dart';
import 'package:campfire/data_structure/message_struct.dart';

class Chat {
  String groupId;
  bool isPublic;
  List<Message> messages; // List of message structures
  List<Event> events; // List of events

  Chat({
    required this.groupId,
    required this.isPublic,
    required this.messages,
    required this.events,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'isPublic': isPublic,
      'messages': messages.map((m) => m.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  static Chat fromJson(Map<String, dynamic> json) {
    return Chat(
      groupId: json['groupId'],
      isPublic: json['isPublic'],
      messages: (json['messages'] as List).map((m) => Message.fromJson(m)).toList(),
      events: (json['events'] as List).map((e) => Event.fromJson(e)).toList(),
    );
  }
}
