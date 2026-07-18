import 'package:chess/chess.dart';

void main() {
  var chess = Chess();
  chess.load_pgn("1. e4 e5 2. Nf3 Nc6");
  
  var move = chess.undo();
  print(move);
  // print properties of move
  // since we don't know the exact class, we can print its type
  print(move.runtimeType);
}
