import 'package:flutter/material.dart';

class CapturedPiecesWidget extends StatelessWidget {
  final String currentFen;
  final bool isWhite;

  const CapturedPiecesWidget({
    super.key,
    required this.currentFen,
    required this.isWhite,
  });

  Map<String, int> _getCapturedPieces(String fen) {
    final initialPieces = {
      'p': 8, 'n': 2, 'b': 2, 'r': 2, 'q': 1,
      'P': 8, 'N': 2, 'B': 2, 'R': 2, 'Q': 1,
    };
    final currentPieces = <String, int>{};
    
    final boardPart = fen.split(' ')[0];
    for (int i = 0; i < boardPart.length; i++) {
      final char = boardPart[i];
      if (initialPieces.containsKey(char)) {
        currentPieces[char] = (currentPieces[char] ?? 0) + 1;
      }
    }

    final captured = <String, int>{};
    initialPieces.forEach((piece, count) {
      int currentCount = currentPieces[piece] ?? 0;
      if (count > currentCount) {
        captured[piece] = count - currentCount;
      }
    });

    return captured;
  }

  String _getPieceAssetPath(String char) {
    bool isPieceWhite = char == char.toUpperCase();
    String colorPrefix = isPieceWhite ? 'w' : 'b';
    String pieceType = char.toLowerCase();
    return 'assets/pieces/$colorPrefix$pieceType.png';
  }

  @override
  Widget build(BuildContext context) {
    final captured = _getCapturedPieces(currentFen);
    List<Widget> pieces = [];
    
    final keys = isWhite 
        ? ['P', 'N', 'B', 'R', 'Q'] 
        : ['p', 'n', 'b', 'r', 'q'];
        
    for (String key in keys) {
      if (captured.containsKey(key) && captured[key]! > 0) {
        for (int i = 0; i < captured[key]!; i++) {
          pieces.add(
            Image.asset(
              _getPieceAssetPath(key),
              width: 36,
              height: 36,
            )
          );
        }
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pieces.isNotEmpty ? pieces : [const SizedBox(height: 16)],
    );
  }
}
