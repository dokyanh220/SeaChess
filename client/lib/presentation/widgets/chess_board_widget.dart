import 'package:client/domain/utils/fen_parser.dart';
import 'package:flutter/material.dart';

class ChessBoardWidget extends StatefulWidget {
  final String fen;
  final String myColor;
  final String kingInCheckSquare;
  final List<String> attackerSquares;
  final Function(String from, String to)? onMove;

  const ChessBoardWidget({
    super.key,
    this.fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    this.myColor = 'white',
    this.kingInCheckSquare = '',
    this.attackerSquares = const [],
    this.onMove,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
    final boardArray = FenParser.parseBoard(widget.fen);

    final bool isFlipped = widget.myColor == 'black';

    List<String> fenParts = widget.fen.split(' ');
    String currentTurn = fenParts.length > 1 ? fenParts[1] : 'w';
    bool isMyTurn =
        (widget.myColor == 'white' && currentTurn == 'w') ||
        (widget.myColor == 'black' && currentTurn == 'b');

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
            bool isLightSquare = (logicalRow + logicalCol) % 2 == 0;
            String piece = boardArray[logicalIndex];
            String squareName = _getSquareName(logicalRow, logicalCol);

            bool isCheckSquare = widget.kingInCheckSquare == squareName ||
                widget.attackerSquares.contains(squareName);

            bool isMyPiece = piece.isNotEmpty &&
                ((widget.myColor == 'white' && piece == piece.toUpperCase()) ||
                    (widget.myColor == 'black' && piece == piece.toLowerCase()));

            bool canDrag = isMyTurn && isMyPiece;

            Color baseColor = isLightSquare ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);
            Color coordColor = isLightSquare ? const Color(0xFFB58863) : const Color(0xFFF0D9B5);

            // Xây dựng widget hiển thị quân cờ lớn hơn (Padding = 0 hoặc nhỏ lại)
            Widget pieceWidget = piece.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(2.0), // Giảm padding để quân cờ to hơn
                    child: Image.asset(_getPieceAssetPath(piece)),
                  )
                : const SizedBox.shrink();

            if (piece.isNotEmpty && canDrag) {
              pieceWidget = Draggable<String>(
                data: squareName,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 70, // Cho dragging feedback to hơn một chút
                    height: 70,
                    child: Image.asset(_getPieceAssetPath(piece)),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Image.asset(_getPieceAssetPath(piece)),
                  ),
                ),
                child: pieceWidget,
              );
            }

            // Xây dựng background có animate nếu bị chiếu
            Widget backgroundWidget = Container(color: baseColor);
            if (isCheckSquare) {
              backgroundWidget = AnimatedBuilder(
                animation: _blinkAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Container(color: baseColor),
                      Container(color: Colors.red.withOpacity(_blinkAnimation.value)),
                    ],
                  );
                },
              );
            }

            return DragTarget<String>(
              onAcceptWithDetails: (details) {
                final fromSquare = details.data;
                if (fromSquare != squareName && widget.onMove != null) {
                  widget.onMove!(fromSquare, squareName);
                }
              },
              builder: (context, candidateData, rejectData) {
                return Stack(
                  children: [
                    // 1. Lớp background (Bao gồm màu ô và nhấp nháy đỏ)
                    Positioned.fill(child: backgroundWidget),

                    // 2. Tọa độ số (cột trái)
                    if (col == 0)
                      Positioned(
                        top: 2,
                        left: 4,
                        child: Text(
                          (8 - logicalRow).toString(),
                          style: TextStyle(
                            color: coordColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),

                    // 3. Tọa độ chữ (hàng dưới)
                    if (row == 7)
                      Positioned(
                        bottom: 2,
                        right: 4,
                        child: Text(
                          String.fromCharCode(97 + logicalCol),
                          style: TextStyle(
                            color: coordColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),

                    // 4. Lớp quân cờ ở trên cùng để không bị block Drag
                    Positioned.fill(
                      child: Center(child: pieceWidget),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
