import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:flutter/material.dart';

/// The round close button that overhangs a card's top-end corner.
///
/// Place it in a [Stack] with [Clip.none] around the card.
class CloseBadge extends StatelessWidget {
  /// Creates a close button that calls [onClose].
  const CloseBadge({
    required this.onClose,
    required this.theme,
    required this.label,
    super.key,
  });

  /// Called when the button is tapped.
  final VoidCallback onClose;

  /// A resolved theme.
  final CricketScoreThemeData theme;

  /// Accessibility label.
  final String label;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: -theme.closeButtonOffset!,
      end: -theme.closeButtonOffset!,
      child: Semantics(
        container: true,
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onClose,
          child: Container(
            width: theme.closeButtonSize,
            height: theme.closeButtonSize,
            decoration: BoxDecoration(
              color: theme.closeButtonBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.closeButtonBorder!,
                width: theme.closeButtonBorderWidth!,
              ),
            ),
            child: Center(
              child: Icon(Icons.close, color: theme.closeIconColor),
            ),
          ),
        ),
      ),
    );
  }
}
