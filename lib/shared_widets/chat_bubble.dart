import 'package:flutter/material.dart';
import 'package:campfire/theme/app_colors.dart';

// Chat Bubble for messages from the current user
class ChatBubble extends StatelessWidget {
  final String message;
  final DateTime time;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight, // Right-align your own messages
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        padding: const EdgeInsets.all(10.0),
        decoration: const BoxDecoration(
          color: AppColors.darkGreen, // Dark green for your messages
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // Align time to the right
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white), // White text color
            ),
            const SizedBox(height: 5),
            Text(
              _formatTime(time),
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}

// Chat Bubble for messages from other users
class OtherChatBubble extends StatelessWidget {
  final String message;
  final DateTime time;

  const OtherChatBubble({
    Key? key,
    required this.message,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft, // Left-align other people's messages
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        padding: const EdgeInsets.all(10.0),
        decoration: const BoxDecoration(
          color: AppColors.mediumGreen, // Medium green for other people's messages
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align time to the left
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white), // White text color
            ),
            const SizedBox(height: 5),
            Text(
              _formatTime(time),
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
