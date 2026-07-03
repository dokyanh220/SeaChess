class FenParser {
  /// Chuyển chuỗi FEN thành mảng 64 phần tử.
  /// Ô trống là chuỗi rỗng '', có quân cờ sẽ là chữ cái (p, P, r, R...)
  static List<String> parseBoard(String fen) {
    // Lấy phần đầu tiên bỏ qua các thông tin lượt đi
    final boardPart = fen.split(' ')[0];
    final List<String> board = [];

    for (int i = 0; i < boardPart.length; i++) {
      final char = boardPart[i];

      if (char == '/') {
        continue;
      }

      // Nếu là số, thì thêm số lượng ô trống tương ứng
      final emptySquares = int.tryParse(char);
      if (emptySquares != null) {
        for (int j = 0; j < emptySquares; j++) {
          board.add('');
        }
      } else {
        board.add(char); // Nếu là chữ cái, thì đây là một quân cờ
      }
    }

    return board; // Trả về List có size = 64
  }
}
