import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:client/presentation/widgets/chess_board_widget.dart';
import 'package:client/domain/models/match_history_model.dart';

class ReplayScreen extends StatefulWidget {
  final MatchHistoryModel match;

  const ReplayScreen({super.key, required this.match});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  late chess_lib.Chess _chess;
  List<String> _fens = [];
  int _currentIndex = 0;
  
  Timer? _playbackTimer;
  bool _isPlaying = false;
  int _speedMultiplier = 1; // 1, 2, 6
  
  @override
  void initState() {
    super.initState();
    _initReplay();
  }
  
  void _initReplay() {
    _chess = chess_lib.Chess();
    
    // Lưu lại FEN ban đầu
    _fens.add(_chess.fen);
    
    if (widget.match.pgn != null && widget.match.pgn!.isNotEmpty) {
      // Dùng chess package để load PGN (có thể load_pgn trả về boolean)
      bool success = _chess.load_pgn(widget.match.pgn!);
      if (success) {
        // Sau khi load PGN, _chess đang ở trạng thái cuối cùng
        // Lấy lại danh sách history (các nước đi)
        final history = _chess.history;
        
        // Tạo lại từ đầu để lưu FEN từng bước
        var replayChess = chess_lib.Chess();
        for (var move in history) {
          replayChess.move(move);
          _fens.add(replayChess.fen);
        }
      }
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
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
        setState(() {
          _currentIndex++;
        });
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
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _prevStep() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đối thủ: ${widget.match.opponentName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
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
                      ],
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
            
            // Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tốc độ
                      _SpeedButton(
                        label: 'x1',
                        isActive: _speedMultiplier == 1,
                        onTap: () => _setSpeed(1),
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 8),
                      _SpeedButton(
                        label: 'x2',
                        isActive: _speedMultiplier == 2,
                        onTap: () => _setSpeed(2),
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 8),
                      _SpeedButton(
                        label: 'x6',
                        isActive: _speedMultiplier == 6,
                        onTap: () => _setSpeed(6),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _prevStep,
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 36,
                        color: colorScheme.primary,
                      ),
                      FloatingActionButton(
                        onPressed: _togglePlayPause,
                        backgroundColor: colorScheme.primary,
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextStep,
                        icon: const Icon(Icons.skip_next),
                        iconSize: 36,
                        color: colorScheme.primary,
                      ),
                    ],
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
