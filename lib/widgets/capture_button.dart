import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';

class CaptureButton extends StatefulWidget {
  const CaptureButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          _isPressed ? 4.0 : 0.0,
          _isPressed ? 4.0 : 0.0,
          0,
        ),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: nbt.accentYellow,
          shape: BoxShape.circle,
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
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: nbt.accentYellow,
              shape: BoxShape.circle,
              border: Border.all(color: nbt.borderColor, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
