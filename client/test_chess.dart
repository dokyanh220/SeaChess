import 'package:chess/chess.dart';

void main() {
  var chess = Chess();
  var pgn = "1. e4 e5 2. Nf3 Nc6";
  bool success = chess.load_pgn(pgn);
  print('Load success: $success');
  
  List<String> tempFens = [chess.fen];
  while (chess.undo() != null) {
    tempFens.add(chess.fen);
  }
  
  print('Fens length: ${tempFens.length}');
  print(tempFens.reversed.toList());
}
