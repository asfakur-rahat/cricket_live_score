import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A score that glows briefly in [color] when [flash] is set, to draw the
/// eye to new runs or a wicket.
///
/// It flashes when it first shows with [flash] set, and again whenever
/// [text] changes while [flash] is set. [onFlashed] is called as the flash
/// starts. With "reduce motion" on it calls [onFlashed] but stays still.
class FlashingScore extends StatefulWidget {
  /// Creates a score.
  const FlashingScore({
    required this.text,
    required this.style,
    required this.color,
    required this.flash,
    this.onFlashed,
    super.key,
  });

  /// The score.
  final String text;

  /// The style of [text] when it isn't flashing.
  final TextStyle? style;

  /// The colour of the flash.
  final Color color;

  /// Whether the score has changed since it was last seen.
  final bool flash;

  /// Called as a flash starts.
  final VoidCallback? onFlashed;

  @override
  State<FlashingScore> createState() => _FlashingScoreState();
}

class _FlashingScoreState extends State<FlashingScore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  // Set in initState, played in didChangeDependencies, which can read
  // MediaQuery.
  late bool _pending = widget.flash;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pending) _play();
  }

  @override
  void didUpdateWidget(FlashingScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flash && (!oldWidget.flash || oldWidget.text != widget.text)) {
      _play();
    }
  }

  void _play() {
    _pending = false;
    widget.onFlashed?.call();
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controller.forward(from: 0));
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
        // Up quickly, then a slow fade.
        final t = _controller.value;
        final glow = !_controller.isAnimating
            ? 0.0
            : t < 0.12
                ? t / 0.12
                : math.pow(1 - (t - 0.12) / 0.88, 2).toDouble();
        final color = widget.color;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22 * glow),
            borderRadius: BorderRadius.circular(4),
            boxShadow: glow == 0
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45 * glow),
                      blurRadius: 10 * glow,
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              widget.text,
              maxLines: 1,
              style: widget.style?.copyWith(
                color: Color.lerp(widget.style?.color, color, glow),
              ),
            ),
          ),
        );
      },
    );
  }
}
