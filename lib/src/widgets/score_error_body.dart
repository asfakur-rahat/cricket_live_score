import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:flutter/material.dart';

/// The default body of an error card: the message and a retry button.
class ScoreErrorBody extends StatelessWidget {
  /// Creates an error body.
  const ScoreErrorBody({
    required this.labels,
    required this.style,
    required this.onRetry,
    super.key,
  });

  /// Supplies the message and the button label.
  final CricketScoreLabels labels;

  /// Style of the message.
  final TextStyle? style;

  /// Called by the retry button.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(labels.loadFailed, style: style, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: Text(labels.retry)),
      ],
    );
  }
}
