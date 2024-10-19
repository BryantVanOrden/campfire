class Comment {
  String commentId;
  String userId;
  String userName;
  String? userProfileImageUrl;
  String content;
  DateTime timestamp;

  Comment({
    required this.commentId,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static Comment fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'],
      userId: json['userId'],
      userName: json['userName'],
      userProfileImageUrl: json['userProfileImageUrl'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
