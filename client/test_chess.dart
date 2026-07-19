import 'package:chess/chess.dart';

void main() {
  // FEN with White Kingside Rook captured by Black Knight (n at h1), castling rights KQkq intact
  var FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNB1K2n w KQkq - 0 1";
  var chess = Chess.fromFEN(FEN);
  
  print('FEN: ${chess.fen}');
  
  var moves = chess.moves({'square': 'e1', 'verbose': true});
  print('Moves for e1:');
  for (var m in moves) {
    print('  ${m['from']} -> ${m['to']} (flags: ${m['flags']})');
  }
}
