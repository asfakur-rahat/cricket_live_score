import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cricket_live_score/src/models/match_phase.dart';
import 'package:cricket_live_score/src/selection/match_filter.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:flutter/material.dart';

/// The key of the phase filter option for [phase]; `null` is "All".
///
/// For tests that tap the filters.
Key phaseFilterKey(MatchPhase? phase) =>
    ValueKey('cricket_filter.phase.${phase?.name ?? 'all'}');

/// The key of the match-type filter option for [type]; `null` is "All".
///
/// For tests that tap the filters.
Key typeFilterKey(String? type) =>
    ValueKey('cricket_filter.type.${type?.toUpperCase() ?? 'all'}');

const _slide = Duration(milliseconds: 320);
const Curve _slideCurve = Curves.easeOutCubic;

// Live first: it is what people open a score screen for.
const List<MatchPhase> _phaseOrder = [
  MatchPhase.live,
  MatchPhase.upcoming,
  MatchPhase.finished,
];

/// The frosted header of the score screen: a segmented capsule of phases
/// above tabs of match types.
class ScoreFilterBar extends StatelessWidget {
  /// Creates the header. With no phases and no [types] it is empty.
  const ScoreFilterBar({
    required this.filter,
    required this.types,
    required this.showPhases,
    required this.hasLive,
    required this.theme,
    required this.labels,
    required this.onChanged,
    this.inline = false,
    super.key,
  });

  /// The filter in use.
  final CricketMatchFilter filter;

  /// Whether the window is wide: the capsule keeps a capped width, and the
  /// type tabs sit beside it on one row.
  final bool inline;

  /// The match types to offer; empty hides the type tabs.
  final List<String> types;

  /// Whether to show the phase capsule.
  final bool showPhases;

  /// Whether any match is live, which makes the dot on "Live" pulse.
  final bool hasLive;

  /// The resolved theme.
  final CricketScoreThemeData theme;

  /// The text shown.
  final CricketScoreLabels labels;

  /// Called with the new filter when an option is tapped.
  final ValueChanged<CricketMatchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!showPhases && types.isEmpty) return const SizedBox.shrink();

    // A single selected phase or type has a pill or underline; "All" is
    // index 0; several selected at once (only possible from code) has
    // neither.
    int selectedIndex<T>(Set<T> selected, List<T> options) {
      if (selected.isEmpty) return 0;
      if (selected.length > 1) return -1;
      return options.indexOf(selected.single) + 1;
    }

    final upperTypes = {for (final t in filter.types) t.toUpperCase()};
    final gap = theme.smallVerticalGap!;
    final outer = theme.outerPadding!;
    final capsule = showPhases
        ? _GlassSegments(
            label: labels.phaseFilter,
            options: [
              _Option(phaseFilterKey(null), labels.allMatches),
              for (final phase in _phaseOrder)
                _Option(
                  phaseFilterKey(phase),
                  labels.phaseLabel(phase),
                  liveDot: phase == MatchPhase.live,
                ),
            ],
            selected: selectedIndex(filter.phases, _phaseOrder),
            hasLive: hasLive,
            theme: theme,
            onSelected: (i) => onChanged(
              filter.copyWith(
                phases: i == 0 ? const {} : {_phaseOrder[i - 1]},
              ),
            ),
          )
        : null;
    _UnderlineTabs tabs({required bool besideCapsule}) => _UnderlineTabs(
          label: labels.typeFilter,
          options: [
            _Option(typeFilterKey(null), labels.allMatches),
            for (final type in types) _Option(typeFilterKey(type), type),
          ],
          selected: selectedIndex(upperTypes, types),
          multiSelected: upperTypes,
          theme: theme,
          besideCapsule: besideCapsule,
          onSelected: (i) => onChanged(
            filter.copyWith(types: i == 0 ? const {} : {types[i - 1]}),
          ),
        );

    final Widget content;
    if (inline && capsule != null && types.isNotEmpty) {
      // One row: the capsule at its natural width, the tabs in the rest.
      content = Padding(
        padding: EdgeInsets.only(left: outer),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: theme.filterCapsuleMaxWidth!,
              ),
              child: capsule,
            ),
            SizedBox(width: theme.largeHorizontalGap),
            Expanded(child: tabs(besideCapsule: true)),
          ],
        ),
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (capsule != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: outer),
              child: inline
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: theme.filterCapsuleMaxWidth!,
                        ),
                        child: capsule,
                      ),
                    )
                  : capsule,
            ),
          if (capsule != null && types.isNotEmpty) SizedBox(height: gap),
          if (types.isNotEmpty) tabs(besideCapsule: false),
        ],
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ColoredBox(
          color: theme.filterHeaderColor!,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: gap),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _Option {
  const _Option(this.key, this.label, {this.liveDot = false});

  final Key key;
  final String label;
  final bool liveDot;
}

LinearGradient _gradient(CricketScoreThemeData theme) => LinearGradient(
      colors: [theme.filterSelectedStart!, theme.filterSelectedEnd!],
    );

List<BoxShadow> _glow(CricketScoreThemeData theme) => [
      BoxShadow(
        color: theme.filterSelectedStart!.withValues(alpha: 0.35),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ];

/// Equal-width segments in a capsule, with a gradient pill that slides to
/// the selected one.
class _GlassSegments extends StatelessWidget {
  const _GlassSegments({
    required this.label,
    required this.options,
    required this.selected,
    required this.hasLive,
    required this.theme,
    required this.onSelected,
  });

  final String label;
  final List<_Option> options;
  final int selected;
  final bool hasLive;
  final CricketScoreThemeData theme;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final height = theme.filterTrackHeight!;
    final inset = theme.smallHorizontalGap!;
    final n = options.length;
    final radius = BorderRadius.circular(height / 2);
    return Semantics(
      container: true,
      label: label,
      child: Container(
        height: height,
        padding: EdgeInsets.all(inset),
        decoration: BoxDecoration(
          color: theme.filterTrackColor,
          borderRadius: radius,
          border: Border.all(color: theme.filterTrackBorder!),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: _slide,
              curve: _slideCurve,
              alignment: Alignment(
                n == 1 ? 0 : -1 + 2 * selected.clamp(0, n - 1) / (n - 1),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: AnimatedOpacity(
                  duration: _slide,
                  opacity: selected < 0 ? 0 : 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _gradient(theme),
                      borderRadius: radius,
                      boxShadow: _glow(theme),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(child: _segment(context, i)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, int index) {
    final option = options[index];
    final isSelected = index == selected;
    final color =
        isSelected ? theme.filterSelectedForeground! : theme.filterForeground!;
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: InkWell(
        key: option.key,
        customBorder: const StadiumBorder(),
        onTap: () => onSelected(index),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.smallHorizontalGap!,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.liveDot) ...[
                    _PulsingDot(
                      color: hasLive
                          ? theme.liveColor!
                          : theme.filterForeground!.withValues(alpha: 0.5),
                      size: theme.mediumHorizontalGap!,
                      pulse: hasLive,
                    ),
                    SizedBox(width: theme.smallHorizontalGap! * 1.5),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: _slide,
                    style: (theme.filterChipStyle ?? const TextStyle())
                        .copyWith(color: color),
                    child: Text(option.label, maxLines: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text tabs that scroll sideways, with a gradient underline that slides to
/// the selected one.
class _UnderlineTabs extends StatefulWidget {
  const _UnderlineTabs({
    required this.label,
    required this.options,
    required this.selected,
    required this.multiSelected,
    required this.theme,
    required this.besideCapsule,
    required this.onSelected,
  });

  final String label;
  final List<_Option> options;
  final int selected;

  /// Whether the tabs sit beside the capsule, which already provides the
  /// space at their start.
  final bool besideCapsule;

  /// Upper-case types selected together, which are highlighted without an
  /// underline.
  final Set<String> multiSelected;
  final CricketScoreThemeData theme;
  final ValueChanged<int> onSelected;

  @override
  State<_UnderlineTabs> createState() => _UnderlineTabsState();
}

class _UnderlineTabsState extends State<_UnderlineTabs> {
  final GlobalKey _stackKey = GlobalKey();
  List<GlobalKey> _tabKeys = [];

  /// Where the underline goes, measured after layout; `null` until then.
  Rect? _underline;

  /// Whether the underline has been placed once; the first placement does
  /// not animate.
  bool _placed = false;

  @override
  void didUpdateWidget(_UnderlineTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected && widget.selected >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tab = _tabKey(widget.selected).currentContext;
        if (mounted && tab != null) {
          unawaited(
            Scrollable.ensureVisible(tab, duration: _slide, curve: _slideCurve),
          );
        }
      });
    }
  }

  GlobalKey _tabKey(int index) {
    while (_tabKeys.length <= index) {
      _tabKeys = [..._tabKeys, GlobalKey()];
    }
    return _tabKeys[index];
  }

  // Runs after every layout: the tabs' widths depend on the text, so the
  // underline can only be placed once they are laid out.
  void _measure() {
    if (!mounted) return;
    Rect? rect;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final index = widget.selected;
    if (stack != null && index >= 0) {
      final tab =
          _tabKey(index).currentContext?.findRenderObject() as RenderBox?;
      if (tab != null && tab.hasSize) {
        rect = tab.localToGlobal(Offset.zero, ancestor: stack) & tab.size;
      }
    }
    if (rect != _underline) {
      setState(() {
        _placed = _underline != null && rect != null;
        _underline = rect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final theme = widget.theme;
    final padX = theme.mediumHorizontalGap! * 1.5;
    final underline = _underline;
    return Semantics(
      container: true,
      label: widget.label,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // The tabs' own padding lines the text up with the capsule above.
        padding: EdgeInsetsDirectional.only(
          start: widget.besideCapsule
              ? 0
              : math.max(0, theme.outerPadding! - padX),
          end: math.max(0, theme.outerPadding! - padX),
        ),
        child: Stack(
          key: _stackKey,
          children: [
            Row(
              children: [
                for (var i = 0; i < widget.options.length; i++) _tab(i, padX),
              ],
            ),
            if (underline != null)
              AnimatedPositioned(
                duration: _placed ? _slide : Duration.zero,
                curve: _slideCurve,
                left: underline.left + padX,
                width: underline.width - 2 * padX,
                bottom: 0,
                height: theme.filterUnderlineHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _gradient(theme),
                    borderRadius: BorderRadius.circular(
                      theme.filterUnderlineHeight!,
                    ),
                    boxShadow: _glow(theme),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tab(int index, double padX) {
    final theme = widget.theme;
    final option = widget.options[index];
    final isSelected = index == widget.selected ||
        (index > 0 &&
            widget.selected < 0 &&
            widget.multiSelected.contains(option.label));
    final base = theme.filterChipStyle ?? const TextStyle();
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: InkWell(
        key: option.key,
        borderRadius: BorderRadius.circular(theme.cardBorderRadius!),
        onTap: () => widget.onSelected(index),
        child: Padding(
          key: _tabKey(index),
          padding: EdgeInsets.symmetric(
            horizontal: padX,
            vertical: theme.smallVerticalGap!,
          ),
          child: AnimatedDefaultTextStyle(
            duration: _slide,
            style: base.copyWith(
              color: isSelected
                  ? theme.filterSelectedStart
                  : theme.filterForeground,
              fontWeight: isSelected ? FontWeight.w800 : base.fontWeight,
            ),
            child: Text(option.label),
          ),
        ),
      ),
    );
  }
}

/// A dot that softly pulses while [pulse] is set and animations are on.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({
    required this.color,
    required this.size,
    required this.pulse,
  });

  final Color color;
  final double size;
  final bool pulse;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate = widget.pulse && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    } else if (!animate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
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
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 1 - 0.45 * t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.55 * (1 - t)),
                blurRadius: widget.size * (0.5 + t),
                spreadRadius: widget.size * 0.25 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
