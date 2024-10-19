import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PaintballGamePage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const PaintballGamePage({super.key, 
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

  String? myPosition;
  String? opponentGuess;
  String? winner;

  int myHearts = 3;
  int opponentHearts = 3;

  bool isMyTurn = false;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    gameRef = _database.ref().child('games/${widget.chatId}');
    _initializeGame();
  }

  void _initializeGame() async {
    DatabaseEvent event = await gameRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value == null) {
      // Initialize game state
      await gameRef.set({
        'player1': widget.currentUserId,
        'player2': widget.otherUserId,
        'currentTurn': widget.currentUserId,
        'hearts': {
          widget.currentUserId: 3,
          widget.otherUserId: 3,
        },
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
          myHearts = gameData['hearts'][widget.currentUserId];
          opponentHearts = gameData['hearts'][widget.otherUserId];
        });
      }
    }

    // Listen for game updates
    gameRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> gameData =
            event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          isMyTurn = gameData['currentTurn'] == widget.currentUserId;
          myHearts = gameData['hearts'][widget.currentUserId];
          opponentHearts = gameData['hearts'][widget.otherUserId];
          winner = gameData['winner'];
          isGameOver = winner != null;
        });
      }
    });
  }

  void _makeMove(String shootPosition) {
    if (!isMyTurn || isGameOver || myPosition == null) return;

    gameRef.child('moves').push().set({
      'shooter': widget.currentUserId,
      'shootPosition': shootPosition,
      'hiddenPosition': myPosition,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    gameRef.update({
      'currentTurn': widget.otherUserId,
    });

    // Check if this move hits the opponent
    _checkForHit(shootPosition);
  }

  void _checkForHit(String shootPosition) {
    gameRef.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> gameData =
            event.snapshot.value as Map<dynamic, dynamic>;
        String opponentHidden = gameData['hiddenPosition'] ?? '';

        // Check if the player hit the opponent's hidden position
        if (opponentHidden == shootPosition) {
          _updateHearts(widget.otherUserId);
        }
      }
    });
  }

  void _updateHearts(String playerId) {
    int hearts = (playerId == widget.currentUserId) ? myHearts - 1 : opponentHearts - 1;

    gameRef.child('hearts').update({
      playerId: hearts,
    });

    if (hearts == 0) {
      gameRef.update({
        'winner': playerId == widget.currentUserId ? widget.otherUserId : widget.currentUserId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paintball Game'),
      ),
      body: Center(
        child: isGameOver
            ? Text(
                winner == widget.currentUserId ? 'You Won!' : 'You Lost!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isMyTurn ? 'Your Turn' : 'Opponent\'s Turn',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  _buildHearts(),
                  const SizedBox(height: 20),
                  _buildGameGrid(),
                ],
              ),
      ),
    );
  }

  Widget _buildHearts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Lives: ❤️ x $myHearts              '),
        Text('Opponent: ❤️ x $opponentHearts'),
      ],
    );
  }

  Widget _buildGameGrid() {
    return Column(
      children: [
        const Text('Your Bushes (Hide behind one):'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHideButton('Left'),
            _buildHideButton('Center'),
            _buildHideButton('Right'),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Shoot at Opponent\'s Bushes:'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShootButton('Left'),
            _buildShootButton('Center'),
            _buildShootButton('Right'),
          ],
        ),
      ],
    );
  }

  Widget _buildHideButton(String position) {
    return GestureDetector(
      onTap: () {
        setState(() {
          myPosition = position;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: myPosition == position ? Colors.green : Colors.grey,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(
            position,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildShootButton(String position) {
    return GestureDetector(
      onTap: () => _makeMove(position),
      child: Container(
        margin: const EdgeInsets.all(8.0),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.red,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(
            position,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
