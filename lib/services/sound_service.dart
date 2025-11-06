import 'package:audioplayers/audioplayers.dart';

/// Service for playing sound effects during scanning
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Play success sound (valid student scanned)
  Future<void> playSuccess() async {
    try {
      await _audioPlayer.stop(); // Stop any currently playing sound
      await _audioPlayer.setVolume(1.0); // Set volume to maximum (100%)
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      // Silently fail if sound file doesn't exist
      // This allows the app to work without sound files
      print('Sound playback failed: $e');
    }
  }

  /// Play error sound (unknown code)
  Future<void> playError() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0); // Set volume to maximum (100%)
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      print('Sound playback failed: $e');
    }
  }

  /// Play duplicate sound (student already scanned)
  Future<void> playDuplicate() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0); // Set volume to maximum (100%)
      await _audioPlayer.play(AssetSource('sounds/duplicate.mp3'));
    } catch (e) {
      print('Sound playback failed: $e');
    }
  }

  /// Dispose of audio player resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
