import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Blurs whatever is behind [barrier] by up to [blur], in step with
/// [animation], so the blur fades in and out with its route.
Widget _blurred(Animation<double> animation, double blur, Widget barrier) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final sigma = blur * animation.value;
      // A disabled filter keeps the tree the same while the route is closed.
      return BackdropFilter(
        enabled: sigma > 0,
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      );
    },
    child: barrier,
  );
}

/// A [DialogRoute] whose barrier also blurs the page behind it by [blur].
class BlurredDialogRoute<T> extends DialogRoute<T> {
  /// Creates a dialog route with a blurred barrier.
  BlurredDialogRoute({
    required super.context,
    required super.builder,
    required this.blur,
    super.themes,
    super.barrierColor,
    super.barrierDismissible,
    super.traversalEdgeBehavior,
  });

  /// The blur sigma once the route is fully open.
  final double blur;

  @override
  Widget buildModalBarrier() =>
      _blurred(animation!, blur, super.buildModalBarrier());
}

/// A [ModalBottomSheetRoute] whose barrier also blurs the page behind it by
/// [blur].
class BlurredBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  /// Creates a bottom sheet route with a blurred barrier.
  BlurredBottomSheetRoute({
    required super.builder,
    required super.isScrollControlled,
    required this.blur,
    super.capturedThemes,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.clipBehavior,
    super.constraints,
    super.modalBarrierColor,
    super.isDismissible,
    super.enableDrag,
    super.useSafeArea,
  });

  /// The blur sigma once the sheet is fully open.
  final double blur;

  @override
  Widget buildModalBarrier() =>
      _blurred(animation!, blur, super.buildModalBarrier());
}
