import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PaintballGamePage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const PaintballGamePage({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  _PaintballGamePageState createState() => _PaintballGamePageState();
}

class _PaintballGamePageState extends State<PaintballGamePage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference gameRef;

  String? myPosition;
  String? myShootPosition;
  String? opponentPosition;
  String? opponentShootPosition;
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

  void _makeMove(String shootPosition) async {
    if (!isMyTurn || isGameOver || myPosition == null) return;

    await gameRef.child('moves').push().set({
      'shooter': widget.currentUserId,
      'shootPosition': shootPosition,
      'hiddenPosition': myPosition,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    gameRef.update({
      'currentTurn': widget.otherUserId,
    });

    setState(() {
      myShootPosition = shootPosition;
    });

    _checkForRoundOutcome();
  }

  void _checkForRoundOutcome() async {
    DatabaseEvent event = await gameRef.once();
    Map<dynamic, dynamic> gameData =
        event.snapshot.value as Map<dynamic, dynamic>;

    // Retrieve the last move from both players
    final lastMoves = gameData['moves'] as Map<dynamic, dynamic>?;
    if (lastMoves == null || lastMoves.length < 2) return;

    final opponentMove = lastMoves.entries.firstWhere(
        (entry) => entry.value['shooter'] != widget.currentUserId);

    setState(() {
      opponentPosition = opponentMove.value['hiddenPosition'];
      opponentShootPosition = opponentMove.value['shootPosition'];
    });

    bool iWasHit = opponentShootPosition == myPosition;
    bool opponentWasHit = myShootPosition == opponentPosition;

    if (iWasHit) {
      _updateHearts(widget.currentUserId);
    }
    if (opponentWasHit) {
      _updateHearts(widget.otherUserId);
    }

    // Show round summary
    await _showRoundSummary(iWasHit, opponentWasHit);
  }

  Future<void> _showRoundSummary(bool iWasHit, bool opponentWasHit) async {
    String message = '';
    if (iWasHit && opponentWasHit) {
      message = 'Both players were hit!';
    } else if (iWasHit) {
      message = 'You were hit!';
    } else if (opponentWasHit) {
      message = 'Your shot hit your opponent!';
    } else {
      message = 'Both players missed!';
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Round Summary'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Check for game over
    if (myHearts == 0 || opponentHearts == 0) {
      _showGameOver();
    }
  }

  void _updateHearts(String playerId) async {
    int hearts = (playerId == widget.currentUserId) ? myHearts - 1 : opponentHearts - 1;

    await gameRef.child('hearts').update({
      playerId: hearts,
    });

    if (hearts == 0) {
      gameRef.update({
        'winner': playerId == widget.currentUserId ? widget.otherUserId : widget.currentUserId,
      });
    }
  }

  Future<void> _showGameOver() async {
    String resultMessage = winner == widget.currentUserId ? 'You Won!' : 'You Lost!';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(resultMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close game page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
