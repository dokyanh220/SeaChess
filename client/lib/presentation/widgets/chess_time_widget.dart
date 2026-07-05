import 'dart:async';

import 'package:flutter/material.dart';

class ChessTimerWidget extends StatefulWidget {
  final double initialTimeMs;
  final bool isRunning;

  const ChessTimerWidget({
    Key? key,
    required this.initialTimeMs,
    required this.isRunning,
  }) : super(key: key);

  @override
  State<ChessTimerWidget> createState() => _ChessTimerWidgetState();
}

class _ChessTimerWidgetState extends State<ChessTimerWidget> {
  late double _timeLeftMs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeftMs = widget.initialTimeMs;
    _checkTimerStatus();
  }

  @override
  void didUpdateWidget(covariant ChessTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi Server (thông qua Provider) ném thời gian thực tế về, ta đồng bộ lại số
    if (oldWidget.initialTimeMs != widget.initialTimeMs) {
      _timeLeftMs = widget.initialTimeMs;
    }
    // Nếu trạng thái lượt đi thay đổi
    if (oldWidget.isRunning != widget.isRunning) {
      _checkTimerStatus();
    }
  }

  void _checkTimerStatus() {
    _timer?.cancel();
    if (widget.isRunning && _timeLeftMs > 0) {
      // Tự đếm lùi 100ms một lần cho mượt giao diện (không cần gọi mạng)
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _timeLeftMs -= 100;
          if (_timeLeftMs <= 0) {
            _timeLeftMs = 0;
            _timer?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    int totalSeconds = (_timeLeftMs / 1000).ceil();
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isRunning
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatTime(),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: widget.isRunning ? Colors.green : Colors.black87,
        ),
      ),
    );
  }
}
