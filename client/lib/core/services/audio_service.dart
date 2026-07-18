import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioService {
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _checkPlayer = AudioPlayer();
  final AudioPlayer _gameOverPlayer = AudioPlayer();

  Future<void> init() async {
    try {
      await _movePlayer.setSource(AssetSource('audio/move.mp3'));
    } catch (e) {
      print("Could not load move.mp3: $e");
    }
    
    try {
      await _checkPlayer.setSource(AssetSource('audio/check.mp3'));
    } catch (e) {
      print("Could not load check.mp3: $e");
    }
    
    try {
      await _gameOverPlayer.setSource(AssetSource('audio/game_over.mp3'));
    } catch (e) {
      print("Could not load game_over.mp3: $e");
    }
  }

  Future<void> playMoveSound() async {
    try {
      await _movePlayer.resume();
    } catch (e) {
      print("Error playing move sound: $e");
    }
  }

  Future<void> playCheckSound() async {
    try {
      await _checkPlayer.resume();
    } catch (e) {
      print("Error playing check sound: $e");
    }
  }

  Future<void> playGameOverSound() async {
    try {
      await _gameOverPlayer.resume();
    } catch (e) {
      print("Error playing game over sound: $e");
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});
