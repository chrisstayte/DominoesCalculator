import 'dart:math';

import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.color,
    this.foregroundColor = Colors.white,
    required this.onTap,
    this.onLongPressComplete,
    this.onShakeTick,
  });

  final IconData icon;
  final Color color;
  final Color foregroundColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPressComplete;
  final VoidCallback? onShakeTick;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _shakeTickHigh = false;

  late final AnimationController _fillController;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _fillController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1500),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onLongPressComplete?.call();
            _shakeController.stop();
            _fillController.reset();
          }
        });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..addListener(() {
        final v = _shakeController.value;
        if (v > 0.9 && !_shakeTickHigh) {
          _shakeTickHigh = true;
          widget.onShakeTick?.call();
        } else if (v < 0.1 && _shakeTickHigh) {
          _shakeTickHigh = false;
          widget.onShakeTick?.call();
        }
      });
  }

  @override
  void dispose() {
    _fillController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onLongPressStart() {
    if (widget.onLongPressComplete == null) return;
    _shakeTickHigh = false;
    _fillController.forward(from: 0);
    _shakeController.repeat(reverse: true);
  }

  void _onLongPressEnd() {
    if (widget.onLongPressComplete == null) return;
    if (_fillController.isAnimating) {
      _shakeController.stop();
      _fillController.reverse();
    }
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final hasLongPress = widget.onLongPressComplete != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPressStart: hasLongPress ? (_) => _onLongPressStart() : null,
      onLongPressEnd: hasLongPress ? (_) => _onLongPressEnd() : null,
      onLongPressDown: hasLongPress
          ? (_) => setState(() => _isPressed = true)
          : null,
      onLongPressCancel: hasLongPress
          ? () {
              setState(() => _isPressed = false);
            }
          : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fillController, _shakeController]),
        builder: (context, child) {
          final maxAngle = _fillController.value * 0.08;
          final rotationAngle = _fillController.isAnimating
              ? sin(_shakeController.value * pi * 2) * maxAngle
              : 0.0;

          final transform = Matrix4.translationValues(
            _isPressed ? 4.0 : 0.0,
            _isPressed ? 4.0 : 0.0,
            0,
          )..rotateZ(rotationAngle);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            curve: Curves.easeOut,
            transform: transform,
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color,
              border: Border.all(color: nbt.borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: nbt.shadowColor,
                  offset: _isPressed ? const Offset(2, 2) : const Offset(6, 6),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              child: Stack(
                children: [
                  if (_fillController.value > 0)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _fillController.value,
                          heightFactor: 1.0,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Icon(
                        widget.icon,
                        color: widget.foregroundColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
