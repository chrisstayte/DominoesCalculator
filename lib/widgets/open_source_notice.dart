import 'package:dominoes/constants.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';

/// Explains the app's AGPL-3.0 license, where its source lives, and the
/// Ultralytics model it bundles.
class OpenSourceNotice extends StatelessWidget {
  const OpenSourceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final color = NeoBrutalistTheme.of(context).secondaryTextColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Text(
        'Domino Counter is free, open-source software licensed under the '
        'GNU Affero General Public License v3.0 (AGPL-3.0). Its complete '
        'source code is available at $sourceRepositoryDisplay.\n\n'
        'Camera detection uses a model trained with Ultralytics YOLO. '
        'Ultralytics code and model weights are licensed under AGPL-3.0.',
        style: TextStyle(color: color, fontSize: 13, height: 1.35),
      ),
    );
  }
}
