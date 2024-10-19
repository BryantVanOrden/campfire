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

  // Selected piece and possible move highlighting
  List<List<bool>> highlighted = List.generate(8, (_) => List.filled(8, false));
  int? selectedRow;
  int? selectedCol;

  @override
  void initState() {
    super.initState();
    gameRef = _database.ref().child('checkers/${widget.chatId}');
    _initializeGame();
  }

  // Initialize or reset the game
  void _initializeGame() async {
    DatabaseEvent event = await gameRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value == null) {
      // Initialize board state with default pieces
      board = _initializeBoard();

      await gameRef.set({
        'player1': widget.currentUserId,
        'player2': widget.otherUserId,
        'currentTurn': widget.currentUserId,
        'board': board,
        'winner': null,
      });
    } else {
      Map<dynamic, dynamic>? gameData = snapshot.value as Map<dynamic, dynamic>?;
      if (gameData != null && gameData['board'] != null) {
        setState(() {
          isMyTurn = gameData['currentTurn'] == widget.currentUserId;
          board = List<List<String?>>.from(
              gameData['board'].map((row) => List<String?>.from(row ?? [])));
          winner = gameData['winner'];
          isGameOver = winner != null;
        });
      }
    }

    // Listen for game updates
    gameRef.onValue.listen((event) {
      Map<dynamic, dynamic>? gameData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (gameData != null && gameData['board'] != null) {
        setState(() {
          isMyTurn = gameData['currentTurn'] == widget.currentUserId;
          board = List<List<String?>>.from(
              gameData['board'].map((row) => List<String?>.from(row ?? [])));
          winner = gameData['winner'];
          isGameOver = winner != null;
        });
      }
    });
  }

  // Set up the initial pieces on the board
  List<List<String?>> _initializeBoard() {
    return List.generate(8, (i) {
      if (i < 3) {
        return List.generate(8, (j) => (i % 2 != j % 2) ? 'O' : null); // Player O (bottom)
      } else if (i > 4) {
        return List.generate(8, (j) => (i % 2 != j % 2) ? 'X' : null); // Player X (top)
      } else {
        return List.filled(8, null); // Empty rows
      }
    });
  }

  // Handle moving a piece
  void _makeMove(int oldRow, int oldCol, int newRow, int newCol) {
    if (!isMyTurn || isGameOver || board[newRow][newCol] != null) return;

    setState(() {
      // Check if a piece was jumped over
      if ((newRow - oldRow).abs() == 2) {
        int middleRow = (newRow + oldRow) ~/ 2;
        int middleCol = (newCol + oldCol) ~/ 2;
        board[middleRow][middleCol] = null; // Remove the jumped piece
      }

      // Move the piece
      board[newRow][newCol] = board[oldRow][oldCol];
      board[oldRow][oldCol] = null;

      // Check for promotion to "king"
      if (newRow == 0 && board[newRow][newCol] == 'X') {
        board[newRow][newCol] = 'XK'; // XK represents a king piece for Player X
      } else if (newRow == 7 && board[newRow][newCol] == 'O') {
        board[newRow][newCol] = 'OK'; // OK represents a king piece for Player O
      }

      highlighted = List.generate(8, (_) => List.filled(8, false)); // Reset highlights
      selectedRow = null;
      selectedCol = null;
    });

    gameRef.update({
      'board': board,
      'currentTurn': widget.otherUserId,
    });

    _checkForWinner();
  }

  // Check if any player has won
  void _checkForWinner() {
    bool xPiecesRemaining = board.any((row) => row.contains('X') || row.contains('XK'));
    bool oPiecesRemaining = board.any((row) => row.contains('O') || row.contains('OK'));

    if (!xPiecesRemaining) {
      gameRef.update({'winner': widget.otherUserId});
    } else if (!oPiecesRemaining) {
      gameRef.update({'winner': widget.currentUserId});
    }
  }

  void _selectPiece(int row, int col) {
    if (board[row][col] == null || !isMyTurn) return;

    setState(() {
      selectedRow = row;
      selectedCol = col;
      highlighted = List.generate(8, (_) => List.filled(8, false));

      // Highlight valid moves
      if (board[row][col] == 'X' || board[row][col] == 'XK') {
        // Normal and king moves for Player X
        if (row > 0 && col > 0 && board[row - 1][col - 1] == null) {
          highlighted[row - 1][col - 1] = true;
        }
        if (row > 0 && col < 7 && board[row - 1][col + 1] == null) {
          highlighted[row - 1][col + 1] = true;
        }
        // King moves can also move backwards
        if (board[row][col] == 'XK') {
          if (row < 7 && col > 0 && board[row + 1][col - 1] == null) {
            highlighted[row + 1][col - 1] = true;
          }
          if (row < 7 && col < 7 && board[row + 1][col + 1] == null) {
            highlighted[row + 1][col + 1] = true;
          }
        }
      } else if (board[row][col] == 'O' || board[row][col] == 'OK') {
        // Normal and king moves for Player O
        if (row < 7 && col > 0 && board[row + 1][col - 1] == null) {
          highlighted[row + 1][col - 1] = true;
        }
        if (row < 7 && col < 7 && board[row + 1][col + 1] == null) {
          highlighted[row + 1][col + 1] = true;
        }
        // King moves can also move backwards
        if (board[row][col] == 'OK') {
          if (row > 0 && col > 0 && board[row - 1][col - 1] == null) {
            highlighted[row - 1][col - 1] = true;
          }
          if (row > 0 && col < 7 && board[row - 1][col + 1] == null) {
            highlighted[row - 1][col + 1] = true;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double boardSize = MediaQuery.of(context).size.width * 0.9; // Ensure board fits well
    double cellSize = boardSize / 8;

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
                  ),
                ],
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isMyTurn ? 'Your Turn' : 'Opponent\'s Turn'),
                const SizedBox(height: 20),
                Center(
                  child: _buildBoard(boardSize, cellSize), // Center the board
                ),
              ],
            ),
    );
  }

  Widget _buildBoard(double boardSize, double cellSize) {
    return GestureDetector(
      onTapUp: (details) {
        double dx = details.localPosition.dx;
        double dy = details.localPosition.dy;

        int row = (dy / cellSize).floor();
        int col = (dx / cellSize).floor();

        if (selectedRow != null && selectedCol != null && board[row][col] == null) {
          _makeMove(selectedRow!, selectedCol!, row, col);
        } else {
          _selectPiece(row, col);
        }
      },
      child: SizedBox(
        width: boardSize,
        height: boardSize,
        child: CustomPaint(
          painter: CheckersPainter(board, highlighted),
        ),
      ),
    );
  }
}

class CheckersPainter extends CustomPainter {
  final List<List<String?>> board;
  final List<List<bool>> highlighted;

  CheckersPainter(this.board, this.highlighted);

  @override
  void paint(Canvas canvas, Size size) {
    double cellSize = size.width / 8;
    Paint darkPaint = Paint()..color = Colors.brown;
    Paint lightPaint = Paint()..color = Colors.brown[300]!;

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        bool isDark = (row + col) % 2 == 1;
        Paint cellPaint = isDark ? darkPaint : lightPaint;
        canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize), cellPaint);

        // Highlight the valid moves
        if (highlighted[row][col]) {
          Paint highlightPaint = Paint()..color = Colors.green.withOpacity(0.5);
          canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize), highlightPaint);
        }

        // Draw pieces
        if (board[row][col] != null) {
          Paint piecePaint = Paint()
            ..color = (board[row][col]!.contains('X')) ? Colors.red : Colors.black;
          canvas.drawCircle(
              Offset(col * cellSize + cellSize / 2, row * cellSize + cellSize / 2), cellSize / 3, piecePaint);

          // Draw a crown for king pieces
          if (board[row][col] == 'XK' || board[row][col] == 'OK') {
            TextPainter textPainter = TextPainter(
              text: const TextSpan(text: 'K', style: TextStyle(color: Colors.yellow, fontSize: 18)),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(
                canvas, Offset(col * cellSize + cellSize / 2 - textPainter.width / 2, row * cellSize + cellSize / 2 - textPainter.height / 2));
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CheckersPainter oldDelegate) {
    return true;
  }
}
