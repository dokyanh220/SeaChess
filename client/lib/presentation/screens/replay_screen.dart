import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:client/presentation/widgets/chess_board_widget.dart';
import 'package:client/domain/models/match_history_model.dart';
import 'package:client/presentation/widgets/captured_pieces_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/services/audio_service.dart';

class ReplayScreen extends ConsumerStatefulWidget {
  final MatchHistoryModel match;

  const ReplayScreen({super.key, required this.match});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  late chess_lib.Chess _chess;
  List<String> _fens = [];
  int _currentIndex = 0;
  
  Timer? _playbackTimer;
  bool _isPlaying = false;
  int _speedMultiplier = 1; // 1, 2, 6
  
  List<String> _moveStrings = [];
  final ScrollController _scrollController = ScrollController();

  void _updateCurrentIndex(int newIndex) {
    if (newIndex < 0 || newIndex >= _fens.length) return;
    if (newIndex != _currentIndex) {
      final fen = _fens[newIndex];
      final chess = chess_lib.Chess.fromFEN(fen);
      final audioService = ref.read(audioServiceProvider);
      
      if (chess.in_checkmate) {
        audioService.playGameOverSound();
      } else if (chess.in_check) {
        audioService.playCheckSound();
      } else {
        audioService.playMoveSound();
      }
    }

    setState(() {
      _currentIndex = newIndex;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        double itemWidth = 85.0; // Ước lượng chiều rộng của mỗi ô (chữ + padding + margin)
        // Tính toán offset để ô hiện tại luôn cách cạnh phải màn hình khoảng 2 ô
        double offset = 16.0 + (newIndex - 1) * itemWidth - MediaQuery.of(context).size.width + (3 * itemWidth);
        
        if (offset < 0) offset = 0;
        if (offset > _scrollController.position.maxScrollExtent) {
          offset = _scrollController.position.maxScrollExtent;
        }
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initReplay();
  }

  void _initReplay() {
    _chess = chess_lib.Chess();
    
    if (widget.match.pgn != null && widget.match.pgn!.isNotEmpty) {
      if (widget.match.pgn!.contains(';')) {
        _fens = widget.match.pgn!.split(';');
      } else {
        bool success = _chess.load_pgn(widget.match.pgn!);
        if (success) {
          List<String> tempFens = [_chess.fen];
          while (_chess.undo() != null) {
            tempFens.add(_chess.fen);
          }
          _fens = tempFens.reversed.toList();
        } else {
          _fens = [widget.match.pgn!];
        }
      }
    } else {
      _fens = [_chess.fen];
    }

    _moveStrings = [];
    for (int i = 1; i < _fens.length; i++) {
      _moveStrings.add(_getMoveString(_fens[i - 1], _fens[i]));
    }
  }

  String _getMoveString(String fen1, String fen2) {
    List<String> board1 = _parseBoard(fen1);
    List<String> board2 = _parseBoard(fen2);
    String from = '';
    String to = '';
    for (int i = 0; i < 64; i++) {
      if (board1[i] != board2[i]) {
        int row = i ~/ 8;
        int col = i % 8;
        String square = '${String.fromCharCode(97 + col)}${8 - row}';
        
        if (board1[i] != '' && board2[i] == '') {
          from = square;
        } else if (board2[i] != '') {
          to = square;
        }
      }
    }
    if (from.isNotEmpty && to.isNotEmpty) return '$from-$to';
    return '';
  }

  List<String> _parseBoard(String fen) {
    if (fen.isEmpty) return List.filled(64, '');
    final boardPart = fen.split(' ')[0];
    final List<String> board = [];
    for (int i = 0; i < boardPart.length; i++) {
      final char = boardPart[i];
      if (char == '/') continue;
      final emptySquares = int.tryParse(char);
      if (emptySquares != null) {
        for (int j = 0; j < emptySquares; j++) board.add('');
      } else {
        board.add(char);
      }
    }
    return board;
  }


  @override
  void dispose() {
    _playbackTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        if (_currentIndex >= _fens.length - 1) {
          _updateCurrentIndex(0);
        }
        _startPlayback();
      } else {
        _playbackTimer?.cancel();
      }
    });
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    
    // Tốc độ: x1 = 1000ms, x2 = 500ms, x6 = 166ms
    int interval = 1000 ~/ _speedMultiplier;
    
    _playbackTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (_currentIndex < _fens.length - 1) {
        _updateCurrentIndex(_currentIndex + 1);
      } else {
        setState(() {
          _isPlaying = false;
        });
        timer.cancel();
      }
    });
  }

  void _setSpeed(int speed) {
    setState(() {
      _speedMultiplier = speed;
      if (_isPlaying) {
        _startPlayback(); // restart timer with new speed
      }
    });
  }

  void _nextStep() {
    if (_currentIndex < _fens.length - 1) {
      _updateCurrentIndex(_currentIndex + 1);
    }
  }

  void _prevStep() {
    if (_currentIndex > 0) {
      _updateCurrentIndex(_currentIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentFen = _fens.isEmpty ? chess_lib.Chess().fen : _fens[_currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem lại trận đấu'),
        backgroundColor: colorScheme.surfaceContainer,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thông tin trận đấu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đối thủ: ${widget.match.opponentName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.match.result == 1 
                                ? 'Trắng thắng' 
                                : widget.match.result == 2 
                                    ? 'Đen thắng' 
                                    : widget.match.result == 3 
                                        ? 'Hòa' 
                                        : 'Đang chờ',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CapturedPiecesWidget(currentFen: currentFen, isWhite: widget.match.isWhite),
                              CapturedPiecesWidget(currentFen: currentFen, isWhite: !widget.match.isWhite),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Nước: $_currentIndex / ${_fens.length - 1}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bàn cờ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: IgnorePointer( // Không cho phép thao tác trên bàn cờ khi xem lại
                    child: ChessBoardWidget(
                      fen: currentFen,
                      myColor: widget.match.isWhite ? 'white' : 'black',
                      kingInCheckSquare: '', 
                      attackerSquares: const [],
                      isLocked: true,
                      onMove: (f, t, p) {},
                    ),
                  ),
                ),
              ),
            ),
            
            // Move history
            if (_moveStrings.isNotEmpty)
              Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _moveStrings.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    bool isCurrent = index + 1 == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        _updateCurrentIndex(index + 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isCurrent ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}. ${_moveStrings[index]}',
                          style: TextStyle(
                            color: isCurrent ? colorScheme.onPrimary : colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
            // Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Tốc độ
                      _SpeedButton(
                        label: 'x1',
                        isActive: _speedMultiplier == 1,
                        onTap: () => _setSpeed(1),
                        colorScheme: colorScheme,
                      ),
                      _SpeedButton(
                        label: 'x2',
                        isActive: _speedMultiplier == 2,
                        onTap: () => _setSpeed(2),
                        colorScheme: colorScheme,
                      ),
                      _SpeedButton(
                        label: 'x6',
                        isActive: _speedMultiplier == 6,
                        onTap: () => _setSpeed(6),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _prevStep,
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 36,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        FloatingActionButton(
                          onPressed: _togglePlayPause,
                          backgroundColor: colorScheme.primary,
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _nextStep,
                          icon: const Icon(Icons.skip_next),
                          iconSize: 36,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _SpeedButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
