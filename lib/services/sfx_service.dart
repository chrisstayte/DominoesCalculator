import 'package:audioplayers/audioplayers.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:flutter/foundation.dart';

class SfxService {
  final LocalSettingsProvider _settingsProvider;
  final List<AudioPlayer> _pool = [];
  final List<AudioPlayer> _available = [];

  static const int _poolSize = 4;

  SfxService(this._settingsProvider);

  Future<void> initialize() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
      for (var i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        _pool.add(player);
        await player.setPlayerMode(PlayerMode.lowLatency);
        _available.add(player);
      }
    } on Exception catch (error) {
      debugPrint('Could not initialize sound effects: $error');
    }
  }

  Future<void> _play(String asset) async {
    if (!_settingsProvider.localSettings.soundEffects || _available.isEmpty) {
      return;
    }
    // Rotate players so short cues can overlap, reserving each during loading.
    final player = _available.removeAt(0);
    try {
      await player.stop();
      await player.setSource(AssetSource('sfx/$asset'));
      if (_settingsProvider.localSettings.soundEffects) await player.resume();
    } on Exception catch (error) {
      debugPrint('Could not play $asset: $error');
    } finally {
      if (_pool.contains(player)) _available.add(player);
    }
  }

  Future<void> playTap() => _play('tap.wav');
  Future<void> playDelete() => _play('delete.wav');
  Future<void> playClear() => _play('clear.wav');
  Future<void> playSuccess() => _play('success.wav');
  Future<void> playToggle() => _play('toggle.wav');
  Future<void> playCapture() => _play('capture.wav');
  Future<void> playNavigate() => _play('navigate.wav');
  Future<void> playOpen() => _play('open.wav');
  Future<void> playClose() => _play('close.wav');

  void dispose() {
    for (final player in _pool) {
      player.dispose();
    }
    _pool.clear();
    _available.clear();
  }
}
