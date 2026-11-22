import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/adaptive_workspace.dart';
import 'package:dominoes/widgets/detection_overlay.dart';
import 'package:flutter/material.dart';

class DominoResultsView extends StatelessWidget {
  final DetectionReport report;
  final int blankValue;
  final bool showConfidence;
  final Color accentColor;
  final VoidCallback onRetake;
  final ValueChanged<List<DominoPips>> onAdd;

  const DominoResultsView({
    super.key,
    required this.report,
    required this.blankValue,
    required this.showConfidence,
    required this.accentColor,
    required this.onRetake,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final complete =
        report.detections.isNotEmpty &&
        report.detections.every((d) => d.hasValues);
    final subtotal = report.detections.fold(
      0,
      (sum, d) => sum + (d.score(blankValue) ?? 0),
    );
    final image = LayoutBuilder(
      builder: (context, constraints) {
        final size = applyBoxFit(
          BoxFit.contain,
          report.imageSize,
          constraints.biggest,
        ).destination;
        return Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    report.imageBytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                  CustomPaint(
                    painter: DetectionOverlay(
                      detections: report.detections,
                      borderColor: accentColor,
                      textColor: Colors.black,
                      badgeColor: accentColor,
                      showConfidence: showConfidence,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    final results = Container(
      color: nbt.cardColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            report.detections.isEmpty
                ? 'NO DOMINOES DETECTED'
                : '${complete ? 'TOTAL' : 'READABLE SUBTOTAL'}: $subtotal · ${report.detections.length} TILES',
            style: TextStyle(
              color: nbt.bodyTextColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            report.detections.isEmpty
                ? 'Try moving closer and keeping the whole tile in view.'
                : 'Check every tile for missed detections and incorrect values. Blanks = $blankValue.',
            style: TextStyle(color: nbt.secondaryTextColor, fontSize: 12),
          ),
          if (report.detections.isNotEmpty) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 112),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: report.detections.length,
                itemBuilder: (context, index) {
                  final d = report.detections[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        if (d.needsReview)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.warning_amber,
                              size: 18,
                              color: nbt.bodyTextColor,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            '#${index + 1}  ${d.label}${d.needsReview ? ' · CHECK' : ''}',
                            style: TextStyle(
                              color: nbt.bodyTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (showConfidence)
                          Text(
                            '${(d.confidence * 100).round()}%',
                            style: TextStyle(color: nbt.secondaryTextColor),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh),
                  label: const Text('RETAKE'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: complete
                      ? () => onAdd([
                          for (final d in report.detections) ...[
                            DominoPips.fromInt(d.pipA!),
                            DominoPips.fromInt(d.pipB!),
                          ],
                        ])
                      : null,
                  child: const Text('ADD TO CALC'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (hasWorkspace(context)) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: WorkspaceSplit(
            leadingFlex: 2,
            trailingFlex: 1,
            leading: image,
            trailing: SingleChildScrollView(child: results),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(child: image),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight * 0.55,
            ),
            child: SingleChildScrollView(child: results),
          ),
        ],
      ),
    );
  }
}
