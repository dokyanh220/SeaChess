import 'package:chess/chess.dart' as ch;

void main() {
  var chess = ch.Chess.fromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
  var m = chess.moves({'square': 'e2', 'verbose': true});
  print(m.first.runtimeType);
  var move = m.first;
  print(move.toAlgebraic);
  print(move.captured);
}
