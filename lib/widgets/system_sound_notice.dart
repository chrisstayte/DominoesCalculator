import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemSoundNotice extends StatelessWidget {
  const SystemSoundNotice({super.key});

  static final _status = const EventChannel(
    'dominoes/systemSound',
  ).receiveBroadcastStream().cast<String>().distinct();

  @override
  Widget build(BuildContext context) {
    final isApple = defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb ||
        (!isApple && defaultTargetPlatform != TargetPlatform.android) ||
        !TickerMode.valuesOf(context).enabled) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<String>(
      stream: _status,
      builder: (context, snapshot) {
        final message = switch (snapshot.data) {
          'silent' => 'Your device is in silent mode.',
          'vibrate' => 'Your device is set to vibrate.',
          'zeroVolume' =>
            isApple
                ? 'Output volume is at zero.'
                : 'System sound volume is muted.',
          _ => isApple ? 'Sound effects follow Silent Mode.' : null,
        };
        if (message == null) return const SizedBox.shrink();
        final muted = snapshot.hasData && snapshot.data != 'normal';
        final color = NeoBrutalistTheme.of(context).secondaryTextColor;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Row(
            children: [
              Icon(
                muted ? Icons.volume_off_outlined : Icons.info_outline,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
