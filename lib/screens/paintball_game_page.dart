import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PaintballGamePage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  PaintballGamePage({
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  _PaintballGamePageState createState() => _PaintballGamePageState();
}

class _PaintballGamePageState extends State<PaintballGamePage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  late DatabaseReference gameRef;

  String? myShipPosition;
  String? opponentShipPosition;
  String? lastMoveBy;
  String? winner;

  bool isMyTurn = false;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    gameRef = _database.ref().child('games/${widget.chatId}');
    _initializeGame();
  }

  void _initializeGame() async {
    DatabaseEvent event = await gameRef.once(); // Get the event
    DataSnapshot snapshot =
        event.snapshot; // Get the DataSnapshot from the event
    if (snapshot.value == null) {
      // Initialize game state
      gameRef.set({
        'player1': widget.currentUserId,
        'player2': widget.otherUserId,
        'currentTurn': widget.currentUserId,
        'moves': {},
        'winner': null,
      });
    } else {
      // Load game state
      Map<dynamic, dynamic> gameData = snapshot.value as Map<dynamic, dynamic>;
      if (gameData['winner'] != null) {
        setState(() {
          winner = gameData['winner'];
          isGameOver = true;
        });
      } else {
        setState(() {
          isMyTurn = gameData['currentTurn'] == widget.currentUserId;
        });
      }
    }

    // Listen for game updates
    gameRef.onValue.listen((event) {
      Map<dynamic, dynamic> gameData =
          event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        isMyTurn = gameData['currentTurn'] == widget.currentUserId;
        winner = gameData['winner'];
        isGameOver = winner != null;
      });
    });
  }

  void _makeMove(String position) {
    if (!isMyTurn || isGameOver) return;

    gameRef.child('moves').child(position).set(widget.currentUserId);
    gameRef.update({
      'currentTurn': widget.otherUserId,
    });

    // Check if this move hits the opponent's ship
    // For simplicity, we'll assume each player has a random ship position at the start
    // In a real game, you would let players choose their ship positions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paintball Game'),
      ),
      body: Center(
        child: isGameOver
            ? Text(
                winner == widget.currentUserId ? 'You Won!' : 'You Lost!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isMyTurn ? 'Your Turn' : 'Opponent\'s Turn',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 20),
                  _buildGameGrid(),
                ],
              ),
      ),
    );
  }

  Widget _buildGameGrid() {
    List<Widget> rows = [];
    for (int row = 0; row < 5; row++) {
      List<Widget> cells = [];
      for (int col = 0; col < 5; col++) {
        String position = '$row$col';
        cells.add(
          GestureDetector(
            onTap: () => _makeMove(position),
            child: Container(
              width: 60,
              height: 60,
              margin: EdgeInsets.all(2),
              color: Colors.grey[300],
              child: Center(child: Text('')),
            ),
          ),
        );
      }
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cells,
      ));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows,
    );
  }
}
