import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TicTacToeGamePage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const TicTacToeGamePage({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  _TicTacToeGamePageState createState() => _TicTacToeGamePageState();
}

class _TicTacToeGamePageState extends State<TicTacToeGamePage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference gameRef;

  List<String> board = List.filled(9, "");
  bool isMyTurn = false;
  bool isGameOver = false;
  String? winner;

  @override
  void initState() {
    super.initState();
    gameRef = _database.ref().child('tic_tac_toe/${widget.chatId}');
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
        'board': List.filled(9, ""),
        'winner': null,
      });
    } else {
      // Load game state
      Map<dynamic, dynamic> gameData = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        isMyTurn = gameData['currentTurn'] == widget.currentUserId;
        board = List<String>.from(gameData['board']);
        winner = gameData['winner'];
        isGameOver = winner != null;
      });
    }

    // Listen for game updates
    gameRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> gameData =
            event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          isMyTurn = gameData['currentTurn'] == widget.currentUserId;
          board = List<String>.from(gameData['board']);
          winner = gameData['winner'];
          isGameOver = winner != null;
        });
      }
    });
  }

  void _makeMove(int index) {
    if (!isMyTurn || isGameOver || board[index].isNotEmpty) return;

    setState(() {
      board[index] = widget.currentUserId == widget.currentUserId ? 'X' : 'O';
    });

    gameRef.update({
      'board': board,
      'currentTurn': widget.otherUserId,
    });

    _checkForWinner();
  }

  void _checkForWinner() {
    const winningCombos = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var combo in winningCombos) {
      if (board[combo[0]] == board[combo[1]] &&
          board[combo[1]] == board[combo[2]] &&
          board[combo[0]].isNotEmpty) {
        gameRef.update({'winner': board[combo[0]] == 'X' ? widget.currentUserId : widget.otherUserId});
        return;
      }
    }

    if (!board.contains("")) {
      gameRef.update({'winner': 'Draw'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
      ),
      body: isGameOver
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(winner == 'Draw' ? 'It\'s a Draw!' : winner == widget.currentUserId ? 'You Won!' : 'You Lost!'),
                  ElevatedButton(
                    onPressed: () {
                      gameRef.remove();
                      _initializeGame();
                    },
                    child: const Text('Restart'),
                  )
                ],
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isMyTurn ? 'Your Turn' : 'Opponent\'s Turn'),
                const SizedBox(height: 20),
                _buildBoard(),
              ],
            ),
    );
  }

  Widget _buildBoard() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _makeMove(index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.black),
            ),
            child: Center(
              child: Text(
                board[index],
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
        );
      },
    );
  }
}
