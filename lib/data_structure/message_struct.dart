class Message {
  String text;
  String senderUid;
  DateTime timeSent;

  Message({
    required this.text,
    required this.senderUid,
    required this.timeSent,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'senderUid': senderUid,
      'timeSent': timeSent.toIso8601String(),
    };
  }

  static Message fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'],
      senderUid: json['senderUid'],
      timeSent: DateTime.parse(json['timeSent']),
    );
  }
}
