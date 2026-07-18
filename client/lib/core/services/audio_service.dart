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
      if (_movePlayer.state == PlayerState.playing) {
        await _movePlayer.stop();
      }
      await _movePlayer.play(AssetSource('audio/move.mp3'));
    } catch (e) {
      print("Error playing move sound: $e");
    }
  }

  Future<void> playCheckSound() async {
    try {
      if (_checkPlayer.state == PlayerState.playing) {
        await _checkPlayer.stop();
      }
      await _checkPlayer.play(AssetSource('audio/check.mp3'));
    } catch (e) {
      print("Error playing check sound: $e");
    }
  }

  Future<void> playGameOverSound() async {
    try {
      if (_gameOverPlayer.state == PlayerState.playing) {
        await _gameOverPlayer.stop();
      }
      await _gameOverPlayer.play(AssetSource('audio/game_over.mp3'));
    } catch (e) {
      print("Error playing game over sound: $e");
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});
