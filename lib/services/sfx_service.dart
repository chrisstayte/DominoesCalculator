import 'package:audioplayers/audioplayers.dart';
import 'package:dominoes/providers/local_settings_provider.dart';

class SfxService {
  final LocalSettingsProvider _settingsProvider;
  final List<AudioPlayer> _pool = [];
  int _nextPlayer = 0;

  static const int _poolSize = 4;

  SfxService(this._settingsProvider);

  Future<void> initialize() async {
    for (var i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      player.setPlayerMode(PlayerMode.lowLatency);
      _pool.add(player);
    }
  }

  AudioPlayer _acquire() {
    final player = _pool[_nextPlayer];
    _nextPlayer = (_nextPlayer + 1) % _poolSize;
    return player;
  }

  Future<void> _play(String asset) async {
    if (!_settingsProvider.localSettings.soundEffects) return;
    try {
      final player = _acquire();
      await player.stop();
      await player.play(AssetSource('sfx/$asset'));
    } catch (_) {
      // Silently fail for missing assets
    }
  }

  Future<void> playTap() => _play('tap.wav');
  Future<void> playDelete() => _play('delete.wav');
  Future<void> playClear() => _play('clear.wav');
  Future<void> playSuccess() => _play('success.wav');
  Future<void> playToggle() => _play('toggle.wav');
  Future<void> playCapture() => _play('capture.wav');

  void dispose() {
    for (final player in _pool) {
      player.dispose();
    }
    _pool.clear();
  }
}
