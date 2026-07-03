import 'package:client/domain/utils/fen_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ChessBoardWidget extends StatelessWidget {
  final String fen;

  const ChessBoardWidget({
    super.key,
    this.fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  });

  String _getPieceAssetPath(String pieceChar) {
    bool isWhite = pieceChar == pieceChar.toUpperCase();
    String colorPrefix = isWhite ? 'white' : 'black';
    String pieceType = pieceChar.toLowerCase();

    return 'assets/pieces/chess-$pieceType-$colorPrefix.png';
  }

  @override
  Widget build(BuildContext context) {
    final boardArray = FenParser.parseBoard(fen);

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

            bool isLightSquare =
                (row + col) % 2 == 0; // đánh dấu caro bằng 1 0 1 0

            String piece = boardArray[index];

            return Container(
              color: isLightSquare
                  ? const Color(0xFFF0D9B5)
                  : const Color(0xFFB58863), // Màu ô cờ bàn
              child: piece.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      // Hiển thị ảnh quân cờ
                      child: Image.asset(_getPieceAssetPath(piece)),
                    )
                  : null, // Không có quân thì rỗng
            );
          },
        ),
      ),
    );
  }
}
