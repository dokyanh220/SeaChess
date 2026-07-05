import 'package:client/domain/utils/fen_parser.dart';
import 'package:flutter/material.dart';

class ChessBoardWidget extends StatelessWidget {
  final String fen;
  final String myColor;
  final Function(String from, String to)? onMove;

  const ChessBoardWidget({
    super.key,
    this.fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    this.myColor = 'white',
    this.onMove,
  });

  String _getPieceAssetPath(String pieceChar) {
    bool isWhite = pieceChar == pieceChar.toUpperCase();
    String colorPrefix = isWhite ? 'w' : 'b';
    String pieceType = pieceChar.toLowerCase();
    return 'assets/pieces/$colorPrefix$pieceType.png';
  }

  String _getSquareName(int row, int col) {
    String file = String.fromCharCode(97 + col); // mã ascii của 'a'
    String rank = (8 - row).toString();
    return '$file$rank';
  }

  @override
  Widget build(BuildContext context) {
    final boardArray = FenParser.parseBoard(fen);

    final bool isFlipped = myColor == 'black';

    List<String> fenParts = fen.split(' ');
    String currentTurn = fenParts.length > 1 ? fenParts[1] : 'w';
    bool isMyTurn =
        (myColor == 'white' && currentTurn == 'w') ||
        (myColor == 'black' && currentTurn == 'b');

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF3E2614), width: 4),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 64,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemBuilder: (context, index) {
            int row = index ~/ 8;
            int col = index % 8;
            int logicalIndex = isFlipped
                ? 63 - index
                : index; // nếu quân đen lật ngược 63 - 0 hoặc 1 - 62(trắng)
            int logicalRow = isFlipped ? 7 - row : row;
            int logicalCol = isFlipped ? 7 - col : col;
            bool isLightSquare =
                (logicalRow + logicalCol) % 2 ==
                0; // đánh dấu caro bằng 1 0 1 0
            String piece = boardArray[logicalIndex];
            String squareName = _getSquareName(logicalRow, logicalCol);

            // Validate lượt đi khóa draggable
            bool isMyPiece =
                piece.isNotEmpty &&
                ((myColor == 'white' && piece == piece.toUpperCase()) ||
                    (myColor == 'black' && piece == piece.toLowerCase()));

            bool canDrag = isMyTurn && isMyPiece;

            return DragTarget<String>(
              onAcceptWithDetails: (details) {
                final fromSquare = details.data;
                final toSquare = squareName;

                if (fromSquare != toSquare && onMove != null) {
                  onMove!(fromSquare, toSquare); // bắn sk
                }
              },
              builder: (context, candidateData, rejectData) {
                return Container(
                  color: isLightSquare
                      ? const Color(0xFFF0D9B5)
                      : const Color(0xFFB58863), // Màu ô cờ bàn
                  child: piece.isNotEmpty
                      ? Draggable<String>(
                          data: squareName,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: Image.asset(_getPieceAssetPath(piece)),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset(_getPieceAssetPath(piece)),
                          ),
                        )
                      : null, // Không có quân thì rỗng
                );
              },
            );
          },
        ),
      ),
    );
  }
}
