import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CheckersGamePage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const CheckersGamePage({
    Key? key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  _CheckersGamePageState createState() => _CheckersGamePageState();
}

class _CheckersGamePageState extends State<CheckersGamePage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference gameRef;

  List<List<String?>> board = List.generate(8, (_) => List.filled(8, null)); // 8x8 Checkers board
  bool isMyTurn = false;
  bool isGameOver = false;
  String? winner;

  // State for selected piece and its possible moves
  List<List<bool>> highlighted = List.generate(8, (_) => List.filled(8, false));
  int? selectedRow;
  int? selectedCol;

  @override
  void initState() {
    super.initState();
    gameRef = _database.ref().child('checkers/${widget.chatId}');
    _initializeGame();
  }

  void _initializeGame() async {
    DatabaseEvent event = await gameRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value == null) {
      // Initialize game state with default pieces
      board = List.generate(8, (i) => i < 3
          ? List.generate(8, (j) => (i % 2 != j % 2) ? 'O' : null)
          : i > 4
              ? List.generate(8, (j) => (i % 2 != j % 2) ? 'X' : null)
              : List.filled(8, null));

      await gameRef.set({
        'player1': widget.currentUserId,
        'player2': widget.otherUserId,
        'currentTurn': widget.currentUserId,
        'board': board,
        'winner': null,
      });
    } else {
      // Load game state
      Map<dynamic, dynamic>? gameData = snapshot.value as Map<dynamic, dynamic>?;
      if (gameData != null && gameData['board'] != null) {
        setState(() {
          isMyTurn = gameData['currentTurn'] == widget.currentUserId;

          // Safeguard to ensure board is in correct format
          if (gameData['board'] != null) {
            board = List<List<String?>>.from(
                gameData['board'].map((row) => List<String?>.from(row ?? [])));
          } else {
            // Fallback to default initialization in case of null or invalid data
            board = List.generate(8, (_) => List.filled(8, null));
          }

          winner = gameData['winner'];
          isGameOver = winner != null;
        });
      }
    }

    // Listen for game updates
    gameRef.onValue.listen((event) {
      Map<dynamic, dynamic>? gameData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (gameData != null) {
        setState(() {
          isMyTurn = gameData['currentTurn'] == widget.currentUserId;

          // Safeguard to ensure board is in correct format
          if (gameData['board'] != null) {
            board = List<List<String?>>.from(
                gameData['board'].map((row) => List<String?>.from(row ?? [])));
          } else {
            // Fallback to default initialization in case of null or invalid data
            board = List.generate(8, (_) => List.filled(8, null));
          }

          winner = gameData['winner'];
          isGameOver = winner != null;
        });
      }
    });
  }

  void _makeMove(int oldRow, int oldCol, int newRow, int newCol) {
    if (!isMyTurn || isGameOver || board[newRow][newCol] != null) return;

    setState(() {
      board[newRow][newCol] = board[oldRow][oldCol];
      board[oldRow][oldCol] = null;
      highlighted = List.generate(8, (_) => List.filled(8, false)); // Reset highlighted cells
      selectedRow = null;
      selectedCol = null;
    });

    gameRef.update({
      'board': board,
      'currentTurn': widget.otherUserId,
    });

    _checkForWinner();
  }

  void _checkForWinner() {
    bool xPiecesRemaining = board.any((row) => row.contains('X'));
    bool oPiecesRemaining = board.any((row) => row.contains('O'));

    if (!xPiecesRemaining) {
      gameRef.update({'winner': widget.otherUserId});
    } else if (!oPiecesRemaining) {
      gameRef.update({'winner': widget.currentUserId});
    }
  }

  void _selectPiece(int row, int col) {
    if (row < 0 || row >= 8 || col < 0 || col >= 8) return; // Boundary check
    if (board[row][col] == null || !isMyTurn) return;

    setState(() {
      selectedRow = row;
      selectedCol = col;
      highlighted = List.generate(8, (_) => List.filled(8, false));

      // Highlight potential moves (with boundary checks to prevent RangeError)
      if (board[row][col] == 'X') {
        if (row > 0 && col > 0 && board[row - 1][col - 1] == null) {
          highlighted[row - 1][col - 1] = true;
        }
        if (row > 0 && col < 7 && board[row - 1][col + 1] == null) {
          highlighted[row - 1][col + 1] = true;
        }
      } else if (board[row][col] == 'O') {
        if (row < 7 && col > 0 && board[row + 1][col - 1] == null) {
          highlighted[row + 1][col - 1] = true;
        }
        if (row < 7 && col < 7 && board[row + 1][col + 1] == null) {
          highlighted[row + 1][col + 1] = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkers Game'),
      ),
      body: isGameOver
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(winner == widget.currentUserId ? 'You Won!' : 'You Lost!'),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(8, (col) {
            return GestureDetector(
              onTap: highlighted[row][col]
                  ? () => _makeMove(selectedRow!, selectedCol!, row, col)
                  : () => _selectPiece(row, col),
              child: Container(
                margin: const EdgeInsets.all(4.0),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlighted[row][col]
                      ? Colors.green
                      : (row + col) % 2 == 0
                          ? Colors.brown[200]
                          : Colors.brown,
                  border: Border.all(color: Colors.black),
                ),
                child: Center(
                  child: Text(
                    board[row][col] ?? '',
                    style: TextStyle(
                      color: board[row][col] == 'X' ? Colors.red : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
