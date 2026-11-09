import 'dart:ui' show ImageFilter;

import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:flutter/material.dart';

/// The score ticker's frosted glass: a blurred, see-through fill inside a
/// thin gradient edge with a soft glow.
///
/// [child] is clipped to the rounded shape and sits on a transparent
/// [Material], so it can use ink splashes.
class TickerGlassFrame extends StatelessWidget {
  /// Frames [child] in the ticker's glass.
  const TickerGlassFrame({
    required this.theme,
    required this.child,
    super.key,
  });

  /// Supplies the colours, blur and shape.
  final CricketScoreThemeData theme;

  /// The ticker's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(theme.tickerBorderRadius!);
    final blur = theme.tickerBlur!;
    final edge = _EdgePainter(
      start: theme.tickerEdgeStart!,
      end: theme.tickerEdgeEnd!,
      glow: theme.tickerGlowColor!,
      radius: theme.tickerBorderRadius!,
    );
    return CustomPaint(
      painter: edge.asGlow(),
      foregroundPainter: edge,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          enabled: blur > 0,
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            type: MaterialType.transparency,
            child: ColoredBox(color: theme.tickerBackground!, child: child),
          ),
        ),
      ),
    );
  }
}

/// Strokes the rounded edge with a gradient, crisp in front of the glass
/// or, as a glow, blurred behind it.
class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.start,
    required this.end,
    required this.glow,
    required this.radius,
    this.isGlow = false,
  });

  final Color start;
  final Color end;
  final Color glow;
  final double radius;
  final bool isGlow;

  _EdgePainter asGlow() => _EdgePainter(
        start: start,
        end: end,
        glow: glow,
        radius: radius,
        isGlow: true,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(radius),
    );
    final paint = Paint()..style = PaintingStyle.stroke;
    if (isGlow) {
      paint
        ..color = glow
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    } else {
      paint
        ..strokeWidth = 1.2
        ..shader = LinearGradient(colors: [start, end]).createShader(rect);
    }
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.end != end ||
      oldDelegate.glow != glow ||
      oldDelegate.radius != radius ||
      oldDelegate.isGlow != isGlow;
}
