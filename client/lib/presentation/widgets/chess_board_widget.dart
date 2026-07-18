import 'package:chess/chess.dart' as ch;
import 'package:client/domain/utils/fen_parser.dart';
import 'package:flutter/material.dart';

class ChessBoardWidget extends StatefulWidget {
  final String fen;
  final String myColor;
  final String kingInCheckSquare;
  final List<String> attackerSquares;

  /// Lock board khi AI đang suy nghĩ
  final bool isLocked;

  /// Callback khi người chơi di chuyển quân.
  /// [promotion] là null nếu không phải phong cấp, ngược lại là 'q'/'r'/'n'/'b'
  final Function(String from, String to, String? promotion)? onMove;

  const ChessBoardWidget({
    super.key,
    this.fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    this.myColor = 'white',
    this.kingInCheckSquare = '',
    this.attackerSquares = const [],
    this.isLocked = false,
    this.onMove,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _blinkAnimation;

  String? _selectedSquare;
  List<Map<String, dynamic>> _validMoves = [];

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

  void _handleSquareTap(String squareName, bool isMyPiece, bool canDrag) {
    // ═══ Lock khi AI đang suy nghĩ ═══
    if (widget.isLocked) return;

    // Nếu bấm vào ô có thể đi, thực hiện di chuyển
    final validMove = _validMoves.cast<Map<String, dynamic>?>().firstWhere(
      (m) => m?['to'] == squareName,
      orElse: () => null,
    );

    if (_selectedSquare != null && validMove != null) {
      final promo = _isPawnPromotion(_selectedSquare!, squareName);
      widget.onMove?.call(_selectedSquare!, squareName, promo);
      setState(() {
        _selectedSquare = null;
        _validMoves = [];
      });
      return;
    }

    // Nếu bấm vào quân của mình, chọn quân đó và tính toán nước đi
    if (canDrag) {
      final chess = ch.Chess.fromFEN(widget.fen);
      final moves = chess.moves({'square': squareName, 'verbose': true});
      setState(() {
        _selectedSquare = squareName;
        _validMoves = moves.cast<Map<String, dynamic>>();
      });
    } else {
      // Bấm ra chỗ khác -> bỏ chọn
      setState(() {
        _selectedSquare = null;
        _validMoves = [];
      });
    }
  }

  /// Kiểm tra nước đi có phải phong cấp tốt không.
  /// Trả về 'promotion' nếu đúng, null nếu không phải.
  /// Việc chọn quân cụ thể (q/r/n/b) do game_screen xử lý.
  String? _isPawnPromotion(String from, String to) {
    final chess = ch.Chess.fromFEN(widget.fen);
    final fromPiece = chess.get(from);
    if (fromPiece == null) return null;
    // Tốt trắng đến hàng 8 (rank index 7), tốt đen đến hàng 1 (rank index 0)
    final toRank = int.tryParse(to[1]) ?? 0;
    
    final isPawn = fromPiece.type == ch.PieceType.PAWN;
    final isPromoRank =
        (fromPiece.color == ch.Color.WHITE && toRank == 8) ||
        (fromPiece.color == ch.Color.BLACK && toRank == 1);
        
    return (isPawn && isPromoRank) ? 'promotion' : null;
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
          image: const DecorationImage(
            image: AssetImage('assets/boards/board.png'),
            fit: BoxFit.cover,
          ),
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

            bool isCheckSquare =
                widget.kingInCheckSquare == squareName ||
                widget.attackerSquares.contains(squareName);

            bool isMyPiece =
                piece.isNotEmpty &&
                ((widget.myColor == 'white' && piece == piece.toUpperCase()) ||
                    (widget.myColor == 'black' &&
                        piece == piece.toLowerCase()));

            bool canDrag = isMyTurn && isMyPiece;

            Color baseColor = isLightSquare
                ? Colors.transparent
                : Colors.black.withOpacity(0.15);
            Color coordColor = isLightSquare
                ? const Color(0xFFB58863)
                : const Color(0xFFF0D9B5);

            Widget pieceWidget = piece.isNotEmpty
                ? Image.asset(_getPieceAssetPath(piece))
                : const SizedBox.shrink();

            if (piece.isNotEmpty && canDrag) {
              pieceWidget = Draggable<String>(
                data: squareName,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 80, // Cho dragging feedback to hơn
                    height: 80,
                    child: Image.asset(_getPieceAssetPath(piece)),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: Image.asset(_getPieceAssetPath(piece)),
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
                      Container(
                        color: Colors.red.withOpacity(_blinkAnimation.value),
                      ),
                    ],
                  );
                },
              );
            } else if (_selectedSquare == squareName) {
              backgroundWidget = Stack(
                children: [
                  Container(color: baseColor),
                  Container(color: Colors.yellow.withOpacity(0.4)),
                ],
              );
            }

            bool isValidMove = _validMoves.any((m) => m['to'] == squareName);
            Widget movePreview = const SizedBox.shrink();
            if (isValidMove) {
              if (piece.isNotEmpty) {
                // Vòng tròn hoặc viền đỏ (ô có quân đối phương để ăn)
                movePreview = Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withOpacity(0.8),
                        width: 4,
                      ),
                    ),
                  ),
                );
              } else {
                // Chấm tròn ở giữa ô (ô trống)
                movePreview = Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
            }

            return GestureDetector(
              onTap: () => _handleSquareTap(squareName, isMyPiece, canDrag),
              child: DragTarget<String>(
                // Validate nước đi hợp lệ khi drag: dùng chess.dart để kiểm tra
                // đảm bảo khi bị chiếu, chỉ các nước thoát chiếu mới được chấp nhận
                onWillAcceptWithDetails: (details) {
                  final fromSquare = details.data;
                  if (fromSquare == squareName) return false;
                  final chess = ch.Chess.fromFEN(widget.fen);
                  final moves = chess.moves({
                    'square': fromSquare,
                    'verbose': true,
                  });
                  return moves.any((m) => (m as Map)['to'] == squareName);
                },
                onAcceptWithDetails: (details) {
                  final fromSquare = details.data;
                  if (fromSquare != squareName && widget.onMove != null) {
                    final promo = _isPawnPromotion(fromSquare, squareName);
                    widget.onMove!(fromSquare, squareName, promo);
                    setState(() {
                      _selectedSquare = null;
                      _validMoves = [];
                    });
                  }
                },
                builder: (context, candidateData, rejectData) {
                  return Stack(
                    children: [
                      // 1. Lớp background (Bao gồm màu ô và nhấp nháy đỏ hoặc highlight)
                      Positioned.fill(child: backgroundWidget),

                      // 2. Move preview (chấm tròn hoặc viền đỏ)
                      if (isValidMove) Positioned.fill(child: movePreview),

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

                      Positioned.fill(child: Center(child: pieceWidget)),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
