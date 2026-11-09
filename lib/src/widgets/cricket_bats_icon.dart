import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Two crossed cricket bats above a ball, drawn in a single [color].
///
/// The default badge between the teams on a `CricketMatchCard`. It fills a
/// [size] × [size] square, so in a round badge pass the badge's diameter.
class CricketBatsIcon extends StatelessWidget {
  /// Creates the icon.
  const CricketBatsIcon({
    required this.color,
    required this.size,
    super.key,
  });

  /// Colour of the bats and ball.
  final Color color;

  /// Width and height of the icon.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _CricketBatsPainter(color)),
    );
  }
}

// Geometry is in a 1024 × 1024 design space, scaled to the widget's size.
class _CricketBatsPainter extends CustomPainter {
  _CricketBatsPainter(this.color);

  final Color color;

  static const _design = 1024.0;

  // Each bat is drawn pointing down its local y axis from the middle of the
  // blade's top edge, then rotated into place.
  static const _bladeHalfWidth = 56.5;
  static const _handleHalfWidth = 26.5;
  static const _bladeLength = 548.0;
  static const _batLength = 875.0;
  static const _endRadius = 16.0;

  // The gap cut into the back bat where the front bat crosses it.
  static const _gap = 9.0;

  static const _ballCenter = Offset(512, 797);
  static const _ballRadius = 72.0;

  static final Path _bat = () {
    const w = _bladeHalfWidth;
    const h = _handleHalfWidth;
    // The shoulders are quarter-circle notches from blade to handle width.
    const shoulder = Radius.circular(w - h);
    const handleStart = _bladeLength + (w - h);
    return Path()
      ..moveTo(-w, 0)
      ..arcToPoint(const Offset(w, 0), radius: const Radius.circular(70))
      ..lineTo(w, _bladeLength)
      ..arcToPoint(
        const Offset(h, handleStart),
        radius: shoulder,
        clockwise: false,
      )
      ..lineTo(h, _batLength - _endRadius)
      ..arcToPoint(
        const Offset(h - _endRadius, _batLength),
        radius: const Radius.circular(_endRadius),
      )
      ..lineTo(-h + _endRadius, _batLength)
      ..arcToPoint(
        const Offset(-h, _batLength - _endRadius),
        radius: const Radius.circular(_endRadius),
      )
      ..lineTo(-h, handleStart)
      ..arcToPoint(
        const Offset(-w, _bladeLength),
        radius: shoulder,
        clockwise: false,
      )
      ..close();
  }();

  static Path _placed(Offset top, double angle) {
    final matrix = Matrix4.translationValues(top.dx, top.dy, 0)
      ..multiply(Matrix4.rotationZ(angle));
    return _bat.transform(matrix.storage);
  }

  // Blade tops sit at the upper corners; the bats cross above the ball.
  static final Path _frontBat = _placed(const Offset(205, 195), -math.pi / 4);
  static final Path _backBat = _placed(const Offset(819, 195), math.pi / 4);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _design, size.height / _design)
      ..saveLayer(Offset.zero & const Size.square(_design), Paint());

    final fill = Paint()..color = color;

    // Clear the front bat's footprint plus the gap, so the bats never
    // overlap, even when the colour is translucent.
    canvas
      ..drawPath(_backBat, fill)
      ..drawPath(_frontBat, Paint()..blendMode = BlendMode.clear)
      ..drawPath(
        _frontBat,
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeWidth = _gap * 2,
      )
      ..drawPath(_frontBat, fill)
      ..drawCircle(_ballCenter, _ballRadius, fill);

    // Seam: one line from the ball's upper right to its lower left, with a
    // row of stitches either side.
    final seam = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas
      ..save()
      ..clipPath(
        Path()
          ..addOval(Rect.fromCircle(center: _ballCenter, radius: _ballRadius)),
      )
      ..translate(_ballCenter.dx, _ballCenter.dy)
      ..rotate(math.pi / 4)
      ..drawLine(
        const Offset(0, -_ballRadius),
        const Offset(0, _ballRadius),
        seam,
      );
    for (final x in [-21.0, 21.0]) {
      for (var y = -_ballRadius + 4; y < _ballRadius; y += 25) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 10), seam);
      }
    }
    canvas
      ..restore()
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(_CricketBatsPainter oldDelegate) =>
      oldDelegate.color != color;
}
