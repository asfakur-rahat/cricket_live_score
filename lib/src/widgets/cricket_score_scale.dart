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
///
/// A [CricketScoreScaleScope] above the widgets can turn scaling off or
/// change the design size and the wide canvas.
@immutable
class CricketScoreScale {
  /// Creates a scale for [canvas]; the default is the design size itself.
  ///
  /// When [enabled] is false, every length is its plain design value
  /// whatever the canvas, and so is every text size.
  const CricketScoreScale({
    this.canvas = designSize,
    this.devicePixelRatio = 1,
    this.design = designSize,
    this.enabled = true,
  });

  /// The scale for the window that [context] is shown in, following the
  /// nearest [CricketScoreScaleScope].
  ///
  /// [wideCanvas], when given, wins over the scope's.
  factory CricketScoreScale.of(BuildContext context, {Size? wideCanvas}) {
    final scope = CricketScoreScaleScope.maybeOf(context);
    final window = MediaQuery.sizeOf(context);
    return CricketScoreScale(
      canvas: isCompactWidth(window.width)
          ? window
          : wideCanvas ?? scope?.wideCanvas ?? defaultWideCanvas,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      design: scope?.designSize ?? designSize,
      enabled: scope?.enabled ?? true,
    );
  }

  /// The screen size the widgets were designed for, unless a
  /// [CricketScoreScaleScope] says otherwise.
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

  /// The screen size the design values are for.
  final Size design;

  /// Whether lengths and text sizes scale at all.
  final bool enabled;

  /// [value], a horizontal length in the [design], scaled to the canvas.
  ///
  /// Use it for widths, radii, paddings and gaps.
  double width(double value) =>
      enabled ? canvas.width * value / design.width : value;

  /// [value], a vertical length in the [design], scaled to the canvas.
  double height(double value) =>
      enabled ? canvas.height * value / design.height : value;

  /// The design text [size] scaled to the canvas.
  ///
  /// The average of the width and height scale, plus a small boost on dense
  /// screens.
  double fontSize(double size) {
    if (!enabled) return size;
    final scaleW = size * canvas.width / design.width;
    final scaleH = size * canvas.height / design.height;
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
      other.devicePixelRatio == devicePixelRatio &&
      other.design == design &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(canvas, devicePixelRatio, design, enabled);

  @override
  String toString() => 'CricketScoreScale(canvas: $canvas, '
      'devicePixelRatio: $devicePixelRatio, design: $design, '
      'enabled: $enabled)';
}

/// Controls how the cricket widgets below it scale their default sizes.
///
/// Without a scope, the defaults scale from a 390 × 850 design to the
/// window, or to a 430 × 937 canvas on a tablet or unfolded foldable (see
/// [CricketScoreScale]). Put one above the widgets, for example in
/// `MaterialApp.builder` so that dialogs and sheets see it too:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => CricketScoreScaleScope(
///     designSize: const Size(375, 812), // your app's design size
///     child: child!,
///   ),
/// );
/// ```
///
/// With [enabled] false, every default size is its plain design value and
/// text keeps the sizes of your text theme. Sizes set in a
/// `CricketScoreThemeData` are always used as given.
class CricketScoreScaleScope extends InheritedWidget {
  /// Creates a scope.
  const CricketScoreScaleScope({
    required super.child,
    this.enabled = true,
    this.designSize = CricketScoreScale.designSize,
    this.wideCanvas = CricketScoreScale.defaultWideCanvas,
    super.key,
  });

  /// Whether default sizes scale with the screen.
  final bool enabled;

  /// The screen size the design values are for: a phone this size gets
  /// the plain design values.
  final Size designSize;

  /// The canvas the design values scale to on a window
  /// [CricketScoreScale.compactMaxWidth] wide or wider.
  final Size wideCanvas;

  /// The nearest scope above [context], if any.
  static CricketScoreScaleScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CricketScoreScaleScope>();

  @override
  bool updateShouldNotify(CricketScoreScaleScope oldWidget) =>
      enabled != oldWidget.enabled ||
      designSize != oldWidget.designSize ||
      wideCanvas != oldWidget.wideCanvas;
}
