import 'package:cricket_live_score/src/controller/cricket_score_controller.dart';
import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:cricket_live_score/src/widgets/cricket_live_score_carousel.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:flutter/material.dart';

/// Shows the live scores as a [CricketLiveScoreCarousel] in a popup dialog
/// and completes when it closes.
///
/// Every card has a close button that closes the dialog. With
/// [barrierDismissible] `false`, a tap outside the cards doesn't close it;
/// the close buttons and the back button still do.
///
/// Pass exactly one of [controller] and [source]; the other arguments are
/// those of [CricketLiveScoreCarousel]. To build the dialog yourself, put a
/// [CricketLiveScoreCarousel] in your own [Dialog].
Future<void> showCricketLiveScoreDialog(
  BuildContext context, {
  CricketScoreController? controller,
  CricketScoreSource? source,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool autoScroll = false,
  Duration autoScrollInterval = const Duration(seconds: 5),
  bool showPageIndicator = false,
  double? maxWidth,
  double? maxHeight,
  void Function(CricketMatch match)? onMatchTap,
  CricketScoreThemeData? theme,
  CricketScoreLabels labels = const CricketScoreLabels(),
  TeamLogoBuilder logoBuilder = defaultTeamLogoBuilder,
  Widget? centerBadge,
  WidgetBuilder? loadingBuilder,
  WidgetBuilder? emptyBuilder,
  CricketScoreErrorBuilder? errorBuilder,
}) {
  assert(
    (controller == null) != (source == null),
    'Pass exactly one of controller and source.',
  );
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    builder: (context) => Dialog(
      // The cards draw their own surface.
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: CricketLiveScoreCarousel(
        controller: controller,
        source: source,
        autoScroll: autoScroll,
        autoScrollInterval: autoScrollInterval,
        showPageIndicator: showPageIndicator,
        onClose: () => Navigator.pop(context),
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        onMatchTap: onMatchTap,
        theme: theme,
        labels: labels,
        logoBuilder: logoBuilder,
        centerBadge: centerBadge,
        loadingBuilder: loadingBuilder,
        emptyBuilder: emptyBuilder,
        errorBuilder: errorBuilder,
      ),
    ),
  );
}
