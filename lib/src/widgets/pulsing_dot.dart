import 'dart:async';

import 'package:flutter/material.dart';

/// A dot that softly pulses while [pulse] is set and animations are on.
class PulsingDot extends StatefulWidget {
  /// Creates a dot of diameter [size].
  const PulsingDot({
    required this.color,
    required this.size,
    required this.pulse,
    super.key,
  });

  /// The colour of the dot and its glow.
  final Color color;

  /// The diameter of the dot.
  final double size;

  /// Whether the dot pulses.
  final bool pulse;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate = widget.pulse && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    } else if (!animate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 1 - 0.45 * t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.55 * (1 - t)),
                blurRadius: widget.size * (0.5 + t),
                spreadRadius: widget.size * 0.25 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
