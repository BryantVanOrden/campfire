import 'package:campfire/screens/checkers.dart';
import 'package:campfire/screens/tic_tac_toe.dart';
import 'package:flutter/material.dart';
import 'paintball_game_page.dart';   // Import your Paintball game page

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Games'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.games),
            title: const Text('Tic Tac Toe'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TicTacToeGamePage(
                    chatId: 'unique_chat_id',
                    currentUserId: 'current_user_id',
                    otherUserId: 'other_user_id',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_esports),
            title: const Text('Paintball Game'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaintballGamePage(
                    chatId: 'unique_chat_id',
                    currentUserId: 'current_user_id',
                    otherUserId: 'other_user_id',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.gamepad),
            title: const Text('Checkers'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CheckersGamePage(
                    chatId: 'unique_chat_id',
                    currentUserId: 'current_user_id',
                    otherUserId: 'other_user_id',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}