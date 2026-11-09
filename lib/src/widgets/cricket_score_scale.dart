import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The screen measurements that the default sizes of the cricket widgets
/// scale with.
///
/// The widgets were designed for a [designSize] phone, and every default gap,
/// radius and text size is that design value scaled to the [canvas]:
///
/// * on a compact window (narrower than [compactMaxWidth]) the canvas is the
///   window, so a smaller phone gets smaller widgets and a larger phone
///   larger ones;
/// * on a wider window (a tablet or an unfolded foldable) the canvas is the
///   fixed phone-sized [defaultWideCanvas], so the widgets do not grow
///   into a giant phone.
@immutable
class CricketScoreScale {
  /// Creates a scale for [canvas]; the default is the design size itself,
  /// where every value is the unscaled design value.
  const CricketScoreScale({
    this.canvas = designSize,
    this.devicePixelRatio = 1,
  });

  /// The scale for the window that [context] is shown in.
  factory CricketScoreScale.of(
    BuildContext context, {
    Size wideCanvas = defaultWideCanvas,
  }) {
    final window = MediaQuery.sizeOf(context);
    return CricketScoreScale(
      canvas: isCompactWidth(window.width) ? window : wideCanvas,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
  }

  /// The screen size the widgets were designed for.
  static const Size designSize = Size(390, 850);

  /// The canvas used on wide windows: a large phone with the design's aspect.
  static const Size defaultWideCanvas = Size(430, 937);

  /// The first window width that is no longer compact, as in Material 3's
  /// window size classes.
  static const double compactMaxWidth = 600;

  /// The width of the Material 3 dialog at its widest.
  static const double maxDialogWidth = 560;

  /// Whether a window [width] counts as compact (a phone held upright).
  static bool isCompactWidth(double width) => width < compactMaxWidth;

  /// The size the design values are scaled to.
  final Size canvas;

  /// The device pixel ratio, which nudges text sizes up on dense screens.
  final double devicePixelRatio;

  /// [value], a horizontal length in the [designSize], scaled to the canvas.
  ///
  /// Use it for widths, radii, paddings and gaps.
  double width(double value) => canvas.width * value / designSize.width;

  /// [value], a vertical length in the [designSize], scaled to the canvas.
  double height(double value) => canvas.height * value / designSize.height;

  /// The design text [size] scaled to the canvas.
  ///
  /// The average of the width and height scale, plus a small boost on dense
  /// screens.
  double fontSize(double size) {
    final scaleW = size * canvas.width / designSize.width;
    final scaleH = size * canvas.height / designSize.height;
    final densityBoost = devicePixelRatio * canvas.width / canvas.height;
    return (scaleW + scaleH + densityBoost) / 2.4;
  }

  /// The width of a centred popup in a window [windowWidth] wide: the window
  /// less a margin on a compact window, capped at [maxDialogWidth] on wider
  /// ones.
  double dialogWidth(double windowWidth) {
    final available = windowWidth - width(32);
    return isCompactWidth(windowWidth)
        ? available
        : math.min(maxDialogWidth, available);
  }

  @override
  bool operator ==(Object other) =>
      other is CricketScoreScale &&
      other.canvas == canvas &&
      other.devicePixelRatio == devicePixelRatio;

  @override
  int get hashCode => Object.hash(canvas, devicePixelRatio);

  @override
  String toString() => 'CricketScoreScale(canvas: $canvas, '
      'devicePixelRatio: $devicePixelRatio)';
}
