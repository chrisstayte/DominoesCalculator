import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _messages = [
  'ANALYZING PIXEL DENSITY...',
  'COUNTING DOTS AGGRESSIVELY...',
  'CONSULTING THE DOMINO GODS...',
  'RECALIBRATING NEURAL MATRIX...',
  'ENHANCING... ENHANCING...',
  'DEPLOYING TINY ROBOTS...',
  'CROSS-REFERENCING PIP DATABASE...',
  'RUNNING DOMINO PHYSICS SIM...',
  'APPLYING MACHINE LEARNING...',
  'WARMING UP THE ALGORITHMS...',
  'SCANNING FOR HIDDEN DOMINOES...',
  'CHECKING UNDER THE TABLE...',
  'CONVERTING TO BINARY DOTS...',
  'OPTIMIZING DOT DETECTION...',
  'RETICULATING SPLINES...',
  'POLISHING EACH PIXEL...',
  'MEASURING DOT ROUNDNESS...',
];

class ProcessingOverlay extends StatefulWidget {
  final String? imagePath;
  final NeoBrutalistTheme nbt;

  const ProcessingOverlay({super.key, this.imagePath, required this.nbt});

  @override
  State<ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<ProcessingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _cursorController;
  late final AnimationController _progressController;
  late final AnimationController _textFadeController;
  Timer? _messageTimer;

  final _rng = Random();
  late List<String> _shuffled;
  int _messageIndex = 0;
  String _currentMessage = '';
  double _progressTarget = 0.0;

  final _logLines = <String>[];

  @override
  void initState() {
    super.initState();

    _shuffled = List.of(_messages)..shuffle(_rng);
    _currentMessage = _shuffled[0];

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    _logLines.add('[OK] IMAGE_CAPTURED');

    _messageTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _cycleMessage();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _bumpProgress();
    });
  }

  void _cycleMessage() {
    _textFadeController.reverse().then((_) {
      if (!mounted) return;

      if (_logLines.length < 3) {
        final tag = _logLines.length < 2 ? '[OK]' : '[..]';
        final logText = switch (_logLines.length) {
          1 => '$tag BUFFER_LOADED',
          _ => '$tag DETECTING...',
        };
        _logLines.add(logText);
      }

      _messageIndex = (_messageIndex + 1) % _shuffled.length;
      _currentMessage = _shuffled[_messageIndex];

      setState(() {});
      _textFadeController.forward();
      _bumpProgress();
    });
  }

  void _bumpProgress() {
    if (!mounted) return;
    final jump = 0.08 + _rng.nextDouble() * 0.10;
    _progressTarget = (_progressTarget + jump).clamp(0.0, 0.90);
    _progressController.animateTo(
      _progressTarget,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _scanController.dispose();
    _cursorController.dispose();
    _progressController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nbt = widget.nbt;

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.imagePath != null)
                Image.file(File(widget.imagePath!), fit: BoxFit.cover),

              Container(color: Colors.black.withValues(alpha: 0.7)),

              // CRT scanline sweep
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) => CustomPaint(
                  painter: _ScanlinePainter(
                    progress: _scanController.value,
                    sweepColor: nbt.accentYellow,
                  ),
                ),
              ),

              // Terminal card
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _buildTerminalCard(nbt),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalCard(NeoBrutalistTheme nbt) {
    return Container(
      decoration: BoxDecoration(
        color: nbt.cardColor,
        border: Border.all(color: nbt.borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: nbt.shadowColor,
            offset: const Offset(6, 6),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleBar(nbt),
          Container(height: 3, color: nbt.borderColor),
          _buildTerminalBody(nbt),
          _buildProgressBar(nbt),
        ],
      ),
    );
  }

  Widget _buildTitleBar(NeoBrutalistTheme nbt) {
    return Container(
      color: nbt.headerColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Square brutalist window dots
          Container(width: 12, height: 12, color: nbt.accentRed),
          const SizedBox(width: 6),
          Container(width: 12, height: 12, color: nbt.accentYellow),
          const SizedBox(width: 6),
          Container(width: 12, height: 12, color: nbt.accentGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Transform(
              transform: Matrix4.skewX(-0.15),
              child: Text(
                'PROCESS_V2.EXE',
                style: GoogleFonts.bricolageGrotesque(
                  color: nbt.headerTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalBody(NeoBrutalistTheme nbt) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in _logLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                line,
                style: GoogleFonts.sourceCodePro(
                  color: line.startsWith('[..]')
                      ? nbt.accentYellow
                      : nbt.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 4),
          FadeTransition(
            opacity: _textFadeController,
            child: Row(
              children: [
                Text(
                  '> ',
                  style: GoogleFonts.sourceCodePro(
                    color: nbt.accentYellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Expanded(
                  child: Text(
                    _currentMessage,
                    style: GoogleFonts.sourceCodePro(
                      color: nbt.bodyTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedBuilder(
                  animation: _cursorController,
                  builder: (context, _) => Opacity(
                    opacity: _cursorController.value > 0.5 ? 1.0 : 0.0,
                    child: Text(
                      '\u2588',
                      style: GoogleFonts.sourceCodePro(
                        color: nbt.accentYellow,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(NeoBrutalistTheme nbt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: nbt.cardColor,
              border: Border.all(color: nbt.borderColor, width: 3),
            ),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressController.value,
                child: Container(color: nbt.accentYellow),
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, _) => Text(
              '${(_progressController.value * 100).toInt()}%  COMPLETE',
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  final Color sweepColor;

  _ScanlinePainter({required this.progress, required this.sweepColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scanlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scanlinePaint);
    }

    final sweepY = size.height * progress;
    const bandHeight = 60.0;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          sweepColor.withValues(alpha: 0.06),
          sweepColor.withValues(alpha: 0.03),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, sweepY - bandHeight / 2, size.width, bandHeight),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, sweepY - bandHeight / 2, size.width, bandHeight),
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) =>
      progress != oldDelegate.progress || sweepColor != oldDelegate.sweepColor;
}
