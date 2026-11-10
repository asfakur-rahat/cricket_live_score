import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cricket_live_score/src/controller/cricket_score_controller.dart';
import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/selection/match_filter.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:cricket_live_score/src/widgets/cricket_live_score_carousel.dart';
import 'package:cricket_live_score/src/widgets/cricket_live_score_view.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_scale.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/score_controller_host.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:flutter/material.dart';

/// Shows the live scores in a draggable modal bottom sheet and completes
/// when it closes.
///
/// The sheet holds a [CricketLiveScoreSheet]: a handle, a title with
/// refresh and close buttons, the filters and the match cards. Drag it
/// between [minChildSize] and [maxChildSize] of the screen height; it opens
/// at [initialChildSize], and dragging it below [minChildSize] closes it. On
/// a phone it is as wide as the screen; on a wider window it is capped at
/// the Material dialog width and centred.
///
/// With [isDismissible] `false`, a tap outside the sheet doesn't close it;
/// with [enableDrag] `false`, dragging it down stops at [minChildSize]
/// instead of closing it. The close button in the title bar and the back
/// button always close it.
///
/// Pass exactly one of [controller] and [source]; the other arguments are
/// those of [CricketLiveScoreView].
Future<void> showCricketLiveScoreSheet(
  BuildContext context, {
  CricketScoreController? controller,
  CricketScoreSource? source,
  String? title,
  CricketMatchFilter initialFilter = CricketMatchFilter.all,
  bool showPhaseFilter = true,
  bool showTypeFilter = true,
  void Function(CricketMatch match)? onMatchTap,
  CricketScoreThemeData? theme,
  CricketScoreLabels labels = const CricketScoreLabels(),
  TeamLogoBuilder logoBuilder = defaultTeamLogoBuilder,
  Widget? centerBadge,
  WidgetBuilder? loadingBuilder,
  WidgetBuilder? emptyBuilder,
  CricketScoreErrorBuilder? errorBuilder,
  double initialChildSize = 0.6,
  double minChildSize = 0.3,
  double maxChildSize = 1,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  assert(
    (controller == null) != (source == null),
    'Pass exactly one of controller and source.',
  );
  final windowWidth = MediaQuery.sizeOf(context).width;
  final maxWidth = CricketScoreScale.isCompactWidth(windowWidth)
      ? double.infinity
      : CricketScoreScale.of(context).dialogWidth(windowWidth);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    // Keeps the frosted top bar inside the sheet's rounded corners.
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints(maxWidth: maxWidth),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      // The modal sheet closes when this one reaches its smallest size,
      // whatever enableDrag says, so turn that off too.
      shouldCloseOnMinExtent: enableDrag,
      builder: (context, scrollController) => CricketLiveScoreSheet(
        controller: controller,
        source: source,
        scrollController: scrollController,
        title: title,
        initialFilter: initialFilter,
        showPhaseFilter: showPhaseFilter,
        showTypeFilter: showTypeFilter,
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

/// The content of the score sheet: a pinned bar with a handle, a title and
/// refresh and close buttons, above a [CricketLiveScoreView].
///
/// [showCricketLiveScoreSheet] puts it in a draggable modal sheet. Use it
/// directly to open the sheet your own way; pass the sheet's
/// [scrollController] so dragging the list resizes the sheet.
///
/// Pull to refresh is off, since pulling down drags the sheet; the refresh
/// button fetches instead.
class CricketLiveScoreSheet extends StatefulWidget {
  /// Creates the sheet content. Exactly one of [controller] and [source]
  /// must be given.
  const CricketLiveScoreSheet({
    super.key,
    this.controller,
    this.source,
    this.scrollController,
    this.title,
    this.onClose,
    this.initialFilter = CricketMatchFilter.all,
    this.showPhaseFilter = true,
    this.showTypeFilter = true,
    this.onMatchTap,
    this.theme,
    this.labels = const CricketScoreLabels(),
    this.logoBuilder = defaultTeamLogoBuilder,
    this.centerBadge,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  }) : assert(
          (controller == null) != (source == null),
          'Pass exactly one of controller and source.',
        );

  /// Supplies the matches; started, paused and disposed by the caller.
  final CricketScoreController? controller;

  /// Supplies the matches through a controller owned by the sheet.
  final CricketScoreSource? source;

  /// The sheet's scroll controller, such as a `DraggableScrollableSheet`'s.
  final ScrollController? scrollController;

  /// The title; `null` shows [CricketScoreLabels.scoresTitle].
  final String? title;

  /// Called by the close button; `null` pops the sheet's route.
  final VoidCallback? onClose;

  /// See [CricketLiveScoreView.initialFilter].
  final CricketMatchFilter initialFilter;

  /// See [CricketLiveScoreView.showPhaseFilter].
  final bool showPhaseFilter;

  /// See [CricketLiveScoreView.showTypeFilter].
  final bool showTypeFilter;

  /// Called when a match card is tapped.
  final void Function(CricketMatch match)? onMatchTap;

  /// Overrides the ambient [CricketScoreThemeData].
  final CricketScoreThemeData? theme;

  /// The text shown by the sheet.
  final CricketScoreLabels labels;

  /// Builds the team logos.
  final TeamLogoBuilder logoBuilder;

  /// Shown inside the badge between the teams on every card.
  final Widget? centerBadge;

  /// See [CricketLiveScoreView.loadingBuilder].
  final WidgetBuilder? loadingBuilder;

  /// See [CricketLiveScoreView.emptyBuilder].
  final WidgetBuilder? emptyBuilder;

  /// See [CricketLiveScoreView.errorBuilder].
  final CricketScoreErrorBuilder? errorBuilder;

  @override
  State<CricketLiveScoreSheet> createState() => _CricketLiveScoreSheetState();
}

class _CricketLiveScoreSheetState extends State<CricketLiveScoreSheet>
    with WidgetsBindingObserver, ScoreControllerHost {
  @override
  CricketScoreController? get widgetController => widget.controller;

  @override
  CricketScoreSource? get widgetSource => widget.source;

  // The view rebuilds itself from the controller; the sheet only needs to
  // know when a refresh it started has finished.
  @override
  void onScoreStateChanged() {}

  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await controller.refresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CricketScoreThemeData.resolve(context, widget.theme);
    return CricketLiveScoreView(
      // The sheet owns the controller so its refresh button can use it.
      controller: controller,
      scrollController: widget.scrollController,
      enablePullToRefresh: false,
      pinnedHeader: _SheetBar(
        title: widget.title ?? widget.labels.scoresTitle,
        refreshing: _refreshing,
        onRefresh: () => unawaited(_refresh()),
        onClose: widget.onClose ?? () => Navigator.maybePop(context),
        theme: theme,
        labels: widget.labels,
      ),
      layout: CricketScoreLayout.phone,
      initialFilter: widget.initialFilter,
      showPhaseFilter: widget.showPhaseFilter,
      showTypeFilter: widget.showTypeFilter,
      onMatchTap: widget.onMatchTap,
      theme: widget.theme,
      labels: widget.labels,
      logoBuilder: widget.logoBuilder,
      centerBadge: widget.centerBadge,
      loadingBuilder: widget.loadingBuilder,
      emptyBuilder: widget.emptyBuilder,
      errorBuilder: widget.errorBuilder,
    );
  }
}

/// The pinned top of the sheet: a drag handle, then the title between a
/// refresh and a close button, on frosted glass.
class _SheetBar extends StatelessWidget {
  const _SheetBar({
    required this.title,
    required this.refreshing,
    required this.onRefresh,
    required this.onClose,
    required this.theme,
    required this.labels,
  });

  final String title;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onClose;
  final CricketScoreThemeData theme;
  final CricketScoreLabels labels;

  @override
  Widget build(BuildContext context) {
    final iconColor = theme.filterForeground;
    final spinnerSize = theme.closeButtonSize! * 0.45;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ColoredBox(
          color: theme.filterHeaderColor!,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.outerPadding!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: theme.smallVerticalGap),
                Container(
                  width: theme.closeButtonSize! * 0.8,
                  height: theme.smallHorizontalGap,
                  decoration: BoxDecoration(
                    color: theme.filterForeground!.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(
                      theme.smallHorizontalGap!,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: theme.sheetTitleStyle),
                      ),
                    ),
                    if (refreshing)
                      SizedBox.square(
                        dimension: theme.closeButtonSize,
                        child: Center(
                          child: SizedBox.square(
                            dimension: spinnerSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.filterSelectedStart,
                            ),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: labels.refresh,
                        color: iconColor,
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    IconButton(
                      tooltip: labels.close,
                      color: iconColor,
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
