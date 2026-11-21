import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/dot_grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _dotGridController;
  late final AnimationController _dominoSlamController;
  late final AnimationController _pipStampController;
  late final AnimationController _titlePunchController;
  late final AnimationController _exitFadeController;

  late final Animation<double> _dotGridOpacity;
  late final Animation<double> _dominoScale;
  late final Animation<double> _pipTopScale;
  late final Animation<double> _pipBottomScale;
  late final Animation<double> _titleScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    // Phase 1: Dot grid fade-in (0–300ms)
    _dotGridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dotGridOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dotGridController, curve: Curves.easeIn),
    );

    // Phase 2: Domino tile slam (300–800ms)
    _dominoSlamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _dominoScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dominoSlamController, curve: Curves.easeOutBack),
    );

    // Phase 3: Pip stamp (800–1400ms) — 200ms stagger between top and bottom
    _pipStampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pipTopScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pipStampController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _pipBottomScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pipStampController,
        curve: const Interval(0.33, 0.88, curve: Curves.easeOutBack),
      ),
    );

    // Phase 4: Title punch (1400–1900ms)
    _titlePunchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _titleScale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _titlePunchController, curve: Curves.easeOutBack),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titlePunchController, curve: Curves.easeOut),
    );

    // Phase 5: Exit fade (2100–2500ms)
    _exitFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitFadeController, curve: Curves.easeIn),
    );

    // Chain animations sequentially
    _dotGridController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dominoSlamController.forward();
      }
    });
    _dominoSlamController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pipStampController.forward();
      }
    });
    _pipStampController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _titlePunchController.forward();
      }
    });
    _titlePunchController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _exitFadeController.forward();
        });
      }
    });
    _exitFadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    // Start the sequence
    _dotGridController.forward();
  }

  @override
  void dispose() {
    _dotGridController.dispose();
    _dominoSlamController.dispose();
    _pipStampController.dispose();
    _titlePunchController.dispose();
    _exitFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _dotGridController,
        _dominoSlamController,
        _pipStampController,
        _titlePunchController,
        _exitFadeController,
      ]),
      builder: (context, _) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: Material(
            color: nbt.dotGridBackground,
            child: Stack(
              children: [
                // Dot grid background
                Positioned.fill(
                  child: Opacity(
                    opacity: _dotGridOpacity.value,
                    child: CustomPaint(
                      painter: DotGridPainter(
                        backgroundColor: nbt.dotGridBackground,
                        dotColor: nbt.dotGridDotColor,
                      ),
                    ),
                  ),
                ),
                // Centered domino + title
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Domino tile
                      Transform.scale(
                        scale: _dominoScale.value,
                        child: _buildDominoTile(nbt),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Opacity(
                        opacity: _titleOpacity.value,
                        child: Transform.scale(
                          scale: _titleScale.value,
                          child: Transform(
                            transform: Matrix4.skewX(-0.15),
                            child: Container(
                              color: nbt.headerColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Text(
                                'DOMINOES',
                                style: GoogleFonts.bricolageGrotesque(
                                  color: nbt.headerTextColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDominoTile(NeoBrutalistTheme nbt) {
    const tileWidth = 140.0;
    const tileHeight = 240.0;

    return Container(
      width: tileWidth,
      height: tileHeight,
      decoration: BoxDecoration(
        color: nbt.cardColor,
        border: Border.all(color: nbt.borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: nbt.shadowColor,
            offset: const Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top half — five pips
          Expanded(
            child: Center(
              child: Transform.scale(
                scale: _pipTopScale.value,
                child: SvgPicture.asset(
                  'assets/images/pips/five_black.svg',
                  width: 80,
                  height: 80,
                  colorFilter: ColorFilter.mode(
                    nbt.bodyTextColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          // Divider line
          Container(
            height: 4,
            color: nbt.borderColor,
          ),
          // Bottom half — four pips
          Expanded(
            child: Center(
              child: Transform.scale(
                scale: _pipBottomScale.value,
                child: SvgPicture.asset(
                  'assets/images/pips/four_black.svg',
                  width: 80,
                  height: 80,
                  colorFilter: ColorFilter.mode(
                    nbt.bodyTextColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
