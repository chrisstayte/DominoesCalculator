import 'package:dominoes/widgets/dot_grid_painter.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _tile = AssetImage('assets/images/launch_icon.png');
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final binding = WidgetsBinding.instance;
    binding.deferFirstFrame();
    precacheImage(_tile, context).whenComplete(() {
      binding.allowFirstFrame();
      if (mounted) {
        _motion.forward().whenCompleteOrCancel(() {
          if (mounted && _motion.isCompleted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final entrance = const Interval(
          0,
          .45,
          curve: Curves.easeOutBack,
        ).transform(_motion.value);
        final title = const Interval(.2, .5).transform(_motion.value);
        final exit = const Interval(
          .74,
          1,
          curve: Curves.easeIn,
        ).transform(_motion.value);
        return Opacity(
          opacity: 1 - exit,
          child: Material(
            color: Colors.white,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: DotGridPainter(
                    backgroundColor: Colors.white,
                    dotColor: const Color(0xffe0e0e0),
                    centered: true,
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, -24 * entrance),
                    child: Transform.scale(
                      scale: 1 + .5 * entrance - .18 * exit,
                      child: const Image(image: _tile, width: 144, height: 144),
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, 100 + 8 * (1 - title)),
                    child: Opacity(
                      opacity: title,
                      child: Transform(
                        transform: Matrix4.skewX(-.15),
                        child: Container(
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: const Text(
                            'DOMINOES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
