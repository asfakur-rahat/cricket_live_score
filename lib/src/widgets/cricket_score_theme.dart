import 'dart:ui' show lerpDouble;

import 'package:cricket_live_score/src/widgets/cricket_score_scale.dart';
import 'package:flutter/material.dart';

/// Colours, sizes and text styles of the cricket score widgets.
///
/// Every field is optional. A widget resolves each field from, in order, its
/// own `theme` argument, a [CricketScoreThemeData] registered in
/// [ThemeData.extensions], and defaults derived from the ambient
/// [ColorScheme] and [TextTheme]. See [CricketScoreThemeData.resolve].
///
/// Sizes are logical pixels. The defaults scale with the screen (see
/// [CricketScoreScale]); a size set here is used as given.
@immutable
class CricketScoreThemeData extends ThemeExtension<CricketScoreThemeData> {
  /// Creates a theme; unset fields fall back as described on the class.
  const CricketScoreThemeData({
    this.cardColor,
    this.shadowColor,
    this.accentColor,
    this.liveColor,
    this.badgeBackground,
    this.badgeForeground,
    this.closeButtonBackground,
    this.closeButtonBorder,
    this.closeIconColor,
    this.fabBorderColor,
    this.liveChipColor,
    this.liveChipForeground,
    this.cardPadding,
    this.outerPadding,
    this.cardBorderRadius,
    this.cardElevation,
    this.closeButtonSize,
    this.closeButtonOffset,
    this.closeButtonBorderWidth,
    this.logoRadius,
    this.badgeRadius,
    this.dividerHeight,
    this.loadingCardSize,
    this.smallHorizontalGap,
    this.mediumHorizontalGap,
    this.largeHorizontalGap,
    this.smallVerticalGap,
    this.mediumVerticalGap,
    this.headerTrailingGap,
    this.fabLogoRadius,
    this.fabHeight,
    this.fabBorderRadius,
    this.fabElevation,
    this.liveChipTop,
    this.liveChipEnd,
    this.fabPadding,
    this.liveChipPadding,
    this.matchTypeStyle,
    this.liveStyle,
    this.startTimeStyle,
    this.venueStyle,
    this.teamNameStyle,
    this.statusStyle,
    this.scoreStyle,
    this.versusStyle,
    this.liveChipStyle,
    this.messageStyle,
    this.listGap,
    this.filterChipStyle,
    this.filterHeaderColor,
    this.filterTrackColor,
    this.filterTrackBorder,
    this.filterSelectedStart,
    this.filterSelectedEnd,
    this.filterSelectedForeground,
    this.filterForeground,
    this.filterTrackHeight,
    this.filterUnderlineHeight,
    this.filterCapsuleMaxWidth,
    this.gridTileMinWidth,
  });

  /// The defaults derived from [theme]'s colour scheme and text theme, with
  /// sizes and text sizes scaled by [scale].
  ///
  /// Every field of the result is non-null, except text styles that
  /// [theme]'s text theme leaves null.
  factory CricketScoreThemeData.fallback(
    ThemeData theme, [
    CricketScoreScale scale = const CricketScoreScale(),
  ]) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final w = scale.width;
    TextStyle? text(TextStyle? style, double size, [FontWeight? weight]) =>
        style?.copyWith(fontSize: scale.fontSize(size), fontWeight: weight);
    return CricketScoreThemeData(
      cardColor: cs.surface,
      shadowColor: cs.shadow,
      accentColor: cs.primary,
      liveColor: cs.error,
      badgeBackground: cs.primary,
      badgeForeground: cs.onPrimary,
      closeButtonBackground: cs.surface,
      closeButtonBorder: cs.outline,
      closeIconColor: cs.onSurface,
      fabBorderColor: cs.primary,
      liveChipColor: cs.error,
      liveChipForeground: cs.onError,
      cardPadding: w(12),
      outerPadding: w(12),
      cardBorderRadius: w(12) + 2,
      cardElevation: 0,
      closeButtonSize: w(40),
      closeButtonOffset: w(12),
      closeButtonBorderWidth: w(2),
      logoRadius: w(48) / 2,
      badgeRadius: w(32) / 2,
      dividerHeight: w(24),
      loadingCardSize: w(300),
      smallHorizontalGap: w(4),
      mediumHorizontalGap: w(8),
      largeHorizontalGap: w(16),
      smallVerticalGap: scale.height(8),
      mediumVerticalGap: scale.height(16),
      headerTrailingGap: w(32),
      fabLogoRadius: w(32) / 2,
      fabHeight: scale.height(55),
      fabBorderRadius: w(12) + 2,
      fabElevation: w(16),
      liveChipTop: -w(10),
      liveChipEnd: w(40),
      fabPadding: EdgeInsets.symmetric(vertical: w(8), horizontal: w(12)),
      liveChipPadding: EdgeInsets.symmetric(vertical: w(3), horizontal: w(8)),
      matchTypeStyle: text(tt.labelMedium, 13),
      liveStyle: text(tt.titleMedium, 16, FontWeight.w700),
      startTimeStyle: text(tt.bodyMedium, 14),
      venueStyle: text(tt.titleMedium, 16, FontWeight.w600),
      teamNameStyle: text(tt.titleSmall, 14, FontWeight.w700),
      statusStyle: text(tt.titleSmall, 14),
      scoreStyle: text(tt.titleSmall, 14),
      versusStyle: text(tt.labelMedium, 13, FontWeight.w900),
      liveChipStyle: text(tt.labelSmall, 11),
      messageStyle: text(tt.bodyMedium, 14),
      listGap: scale.height(16),
      filterChipStyle: text(tt.labelLarge, 14, FontWeight.w600),
      filterHeaderColor: cs.surface.withValues(alpha: 0.82),
      filterTrackColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      filterTrackBorder: cs.outlineVariant.withValues(alpha: 0.6),
      filterSelectedStart: cs.primary,
      filterSelectedEnd: cs.tertiary,
      filterSelectedForeground: cs.onPrimary,
      filterForeground: cs.onSurfaceVariant,
      filterTrackHeight: w(44),
      filterUnderlineHeight: w(3),
      filterCapsuleMaxWidth: w(420),
      gridTileMinWidth: w(300),
    );
  }

  /// The fully resolved theme for widgets under [context]: [override], then
  /// the [ThemeData.extensions] entry, then [CricketScoreThemeData.fallback]
  /// scaled to the window ([CricketScoreScale.of]).
  factory CricketScoreThemeData.resolve(
    BuildContext context, [
    CricketScoreThemeData? override,
  ]) {
    final theme = Theme.of(context);
    return CricketScoreThemeData.fallback(
      theme,
      CricketScoreScale.of(context),
    ).merge(theme.extension<CricketScoreThemeData>()).merge(override);
  }

  /// Background of the match card and the status card.
  final Color? cardColor;

  /// Shadow under the cards and the floating button.
  final Color? shadowColor;

  /// Colour of the match-type label, for example "T20".
  final Color? accentColor;

  /// Colour of the "- LIVE -" heading on a live match card.
  final Color? liveColor;

  /// Background of the round badge between the two teams.
  final Color? badgeBackground;

  /// Colour of the default crossed-bats icon inside the centre badge.
  final Color? badgeForeground;

  /// Background of the round close button.
  final Color? closeButtonBackground;

  /// Border of the round close button.
  final Color? closeButtonBorder;

  /// Colour of the close icon.
  final Color? closeIconColor;

  /// Border of the floating match button.
  final Color? fabBorderColor;

  /// Background of the LIVE chip on the floating button.
  final Color? liveChipColor;

  /// Text colour of the LIVE chip on the floating button.
  final Color? liveChipForeground;

  /// Padding inside the match card.
  final double? cardPadding;

  /// Space around each card in the carousel; leaves room for the close
  /// button, which overhangs the card.
  final double? outerPadding;

  /// Corner radius of the cards.
  final double? cardBorderRadius;

  /// Elevation of the cards.
  final double? cardElevation;

  /// Diameter of the close button.
  final double? closeButtonSize;

  /// How far the close button overhangs the card's top and end edges.
  final double? closeButtonOffset;

  /// Border width of the close button.
  final double? closeButtonBorderWidth;

  /// Radius of a team logo on the match card.
  final double? logoRadius;

  /// Radius of the centre badge on the match card.
  final double? badgeRadius;

  /// Height of the dividers around the teams row.
  final double? dividerHeight;

  /// Width and height of the loading, empty and error cards.
  final double? loadingCardSize;

  /// Gap between the match type and the start time or LIVE heading.
  final double? smallHorizontalGap;

  /// Gap either side of "VS" on the floating button.
  final double? mediumHorizontalGap;

  /// Gap either side of the centre badge.
  final double? largeHorizontalGap;

  /// Gap between a team logo and its name.
  final double? smallVerticalGap;

  /// Gap below the header row and below the status line.
  final double? mediumVerticalGap;

  /// Space reserved at the end of the header row, under the close
  /// button.
  final double? headerTrailingGap;

  /// Radius of a team logo on the floating button.
  final double? fabLogoRadius;

  /// Height of the floating button.
  final double? fabHeight;

  /// Corner radius of the floating button and its LIVE chip.
  final double? fabBorderRadius;

  /// Elevation of the floating button.
  final double? fabElevation;

  /// Offset of the LIVE chip from the floating button's top edge;
  /// negative values overhang it.
  final double? liveChipTop;

  /// Offset of the LIVE chip from the floating button's end edge.
  final double? liveChipEnd;

  /// Padding inside the floating button.
  final EdgeInsetsGeometry? fabPadding;

  /// Padding inside the LIVE chip.
  final EdgeInsetsGeometry? liveChipPadding;

  /// Style of the match-type label; its colour is [accentColor].
  final TextStyle? matchTypeStyle;

  /// Style of the "- LIVE -" heading; its colour is [liveColor].
  final TextStyle? liveStyle;

  /// Style of the start time shown when a match is not live.
  final TextStyle? startTimeStyle;

  /// Style of the venue line.
  final TextStyle? venueStyle;

  /// Style of the team names.
  final TextStyle? teamNameStyle;

  /// Style of the status line, for example "India won by 5 wickets".
  final TextStyle? statusStyle;

  /// Style of the rows in the score table.
  final TextStyle? scoreStyle;

  /// Style of "VS" on the floating button.
  final TextStyle? versusStyle;

  /// Style of the LIVE chip text; its colour is [liveChipForeground].
  final TextStyle? liveChipStyle;

  /// Style of the message on the empty and error cards.
  final TextStyle? messageStyle;

  /// Space between the match cards on the score screen.
  final double? listGap;

  /// Style of the filter chip labels on the score screen.
  final TextStyle? filterChipStyle;

  /// Background of the frosted filter header on the score screen.
  final Color? filterHeaderColor;

  /// Background of the capsule holding the phase filter.
  final Color? filterTrackColor;

  /// Border of the capsule holding the phase filter.
  final Color? filterTrackBorder;

  /// Start colour of the gradient on the selected filter: the sliding pill
  /// and the underline.
  final Color? filterSelectedStart;

  /// End colour of the gradient on the selected filter.
  final Color? filterSelectedEnd;

  /// Text colour of the selected phase, on the gradient pill.
  final Color? filterSelectedForeground;

  /// Text colour of the filters that are not selected.
  final Color? filterForeground;

  /// Height of the capsule holding the phase filter.
  final double? filterTrackHeight;

  /// Thickness of the underline under the selected match type.
  final double? filterUnderlineHeight;

  /// Widest the phase capsule grows; on a wide screen it sits beside the
  /// type tabs.
  final double? filterCapsuleMaxWidth;

  /// Narrowest a card may be in the adaptive grid; the grid fits as many\n  /// columns as this allows.
  final double? gridTileMinWidth;

  /// Returns a copy in which every non-null field of [other] replaces the
  /// field of this theme.
  CricketScoreThemeData merge(CricketScoreThemeData? other) {
    if (other == null) return this;
    return copyWith(
      cardColor: other.cardColor,
      shadowColor: other.shadowColor,
      accentColor: other.accentColor,
      liveColor: other.liveColor,
      badgeBackground: other.badgeBackground,
      badgeForeground: other.badgeForeground,
      closeButtonBackground: other.closeButtonBackground,
      closeButtonBorder: other.closeButtonBorder,
      closeIconColor: other.closeIconColor,
      fabBorderColor: other.fabBorderColor,
      liveChipColor: other.liveChipColor,
      liveChipForeground: other.liveChipForeground,
      cardPadding: other.cardPadding,
      outerPadding: other.outerPadding,
      cardBorderRadius: other.cardBorderRadius,
      cardElevation: other.cardElevation,
      closeButtonSize: other.closeButtonSize,
      closeButtonOffset: other.closeButtonOffset,
      closeButtonBorderWidth: other.closeButtonBorderWidth,
      logoRadius: other.logoRadius,
      badgeRadius: other.badgeRadius,
      dividerHeight: other.dividerHeight,
      loadingCardSize: other.loadingCardSize,
      smallHorizontalGap: other.smallHorizontalGap,
      mediumHorizontalGap: other.mediumHorizontalGap,
      largeHorizontalGap: other.largeHorizontalGap,
      smallVerticalGap: other.smallVerticalGap,
      mediumVerticalGap: other.mediumVerticalGap,
      headerTrailingGap: other.headerTrailingGap,
      fabLogoRadius: other.fabLogoRadius,
      fabHeight: other.fabHeight,
      fabBorderRadius: other.fabBorderRadius,
      fabElevation: other.fabElevation,
      liveChipTop: other.liveChipTop,
      liveChipEnd: other.liveChipEnd,
      fabPadding: other.fabPadding,
      liveChipPadding: other.liveChipPadding,
      matchTypeStyle: other.matchTypeStyle,
      liveStyle: other.liveStyle,
      startTimeStyle: other.startTimeStyle,
      venueStyle: other.venueStyle,
      teamNameStyle: other.teamNameStyle,
      statusStyle: other.statusStyle,
      scoreStyle: other.scoreStyle,
      versusStyle: other.versusStyle,
      liveChipStyle: other.liveChipStyle,
      messageStyle: other.messageStyle,
      listGap: other.listGap,
      filterChipStyle: other.filterChipStyle,
      filterHeaderColor: other.filterHeaderColor,
      filterTrackColor: other.filterTrackColor,
      filterTrackBorder: other.filterTrackBorder,
      filterSelectedStart: other.filterSelectedStart,
      filterSelectedEnd: other.filterSelectedEnd,
      filterSelectedForeground: other.filterSelectedForeground,
      filterForeground: other.filterForeground,
      filterTrackHeight: other.filterTrackHeight,
      filterUnderlineHeight: other.filterUnderlineHeight,
      filterCapsuleMaxWidth: other.filterCapsuleMaxWidth,
      gridTileMinWidth: other.gridTileMinWidth,
    );
  }

  @override
  CricketScoreThemeData copyWith({
    Color? cardColor,
    Color? shadowColor,
    Color? accentColor,
    Color? liveColor,
    Color? badgeBackground,
    Color? badgeForeground,
    Color? closeButtonBackground,
    Color? closeButtonBorder,
    Color? closeIconColor,
    Color? fabBorderColor,
    Color? liveChipColor,
    Color? liveChipForeground,
    double? cardPadding,
    double? outerPadding,
    double? cardBorderRadius,
    double? cardElevation,
    double? closeButtonSize,
    double? closeButtonOffset,
    double? closeButtonBorderWidth,
    double? logoRadius,
    double? badgeRadius,
    double? dividerHeight,
    double? loadingCardSize,
    double? smallHorizontalGap,
    double? mediumHorizontalGap,
    double? largeHorizontalGap,
    double? smallVerticalGap,
    double? mediumVerticalGap,
    double? headerTrailingGap,
    double? fabLogoRadius,
    double? fabHeight,
    double? fabBorderRadius,
    double? fabElevation,
    double? liveChipTop,
    double? liveChipEnd,
    EdgeInsetsGeometry? fabPadding,
    EdgeInsetsGeometry? liveChipPadding,
    TextStyle? matchTypeStyle,
    TextStyle? liveStyle,
    TextStyle? startTimeStyle,
    TextStyle? venueStyle,
    TextStyle? teamNameStyle,
    TextStyle? statusStyle,
    TextStyle? scoreStyle,
    TextStyle? versusStyle,
    TextStyle? liveChipStyle,
    TextStyle? messageStyle,
    double? listGap,
    TextStyle? filterChipStyle,
    Color? filterHeaderColor,
    Color? filterTrackColor,
    Color? filterTrackBorder,
    Color? filterSelectedStart,
    Color? filterSelectedEnd,
    Color? filterSelectedForeground,
    Color? filterForeground,
    double? filterTrackHeight,
    double? filterUnderlineHeight,
    double? filterCapsuleMaxWidth,
    double? gridTileMinWidth,
  }) {
    return CricketScoreThemeData(
      cardColor: cardColor ?? this.cardColor,
      shadowColor: shadowColor ?? this.shadowColor,
      accentColor: accentColor ?? this.accentColor,
      liveColor: liveColor ?? this.liveColor,
      badgeBackground: badgeBackground ?? this.badgeBackground,
      badgeForeground: badgeForeground ?? this.badgeForeground,
      closeButtonBackground:
          closeButtonBackground ?? this.closeButtonBackground,
      closeButtonBorder: closeButtonBorder ?? this.closeButtonBorder,
      closeIconColor: closeIconColor ?? this.closeIconColor,
      fabBorderColor: fabBorderColor ?? this.fabBorderColor,
      liveChipColor: liveChipColor ?? this.liveChipColor,
      liveChipForeground: liveChipForeground ?? this.liveChipForeground,
      cardPadding: cardPadding ?? this.cardPadding,
      outerPadding: outerPadding ?? this.outerPadding,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      cardElevation: cardElevation ?? this.cardElevation,
      closeButtonSize: closeButtonSize ?? this.closeButtonSize,
      closeButtonOffset: closeButtonOffset ?? this.closeButtonOffset,
      closeButtonBorderWidth:
          closeButtonBorderWidth ?? this.closeButtonBorderWidth,
      logoRadius: logoRadius ?? this.logoRadius,
      badgeRadius: badgeRadius ?? this.badgeRadius,
      dividerHeight: dividerHeight ?? this.dividerHeight,
      loadingCardSize: loadingCardSize ?? this.loadingCardSize,
      smallHorizontalGap: smallHorizontalGap ?? this.smallHorizontalGap,
      mediumHorizontalGap: mediumHorizontalGap ?? this.mediumHorizontalGap,
      largeHorizontalGap: largeHorizontalGap ?? this.largeHorizontalGap,
      smallVerticalGap: smallVerticalGap ?? this.smallVerticalGap,
      mediumVerticalGap: mediumVerticalGap ?? this.mediumVerticalGap,
      headerTrailingGap: headerTrailingGap ?? this.headerTrailingGap,
      fabLogoRadius: fabLogoRadius ?? this.fabLogoRadius,
      fabHeight: fabHeight ?? this.fabHeight,
      fabBorderRadius: fabBorderRadius ?? this.fabBorderRadius,
      fabElevation: fabElevation ?? this.fabElevation,
      liveChipTop: liveChipTop ?? this.liveChipTop,
      liveChipEnd: liveChipEnd ?? this.liveChipEnd,
      fabPadding: fabPadding ?? this.fabPadding,
      liveChipPadding: liveChipPadding ?? this.liveChipPadding,
      matchTypeStyle: matchTypeStyle ?? this.matchTypeStyle,
      liveStyle: liveStyle ?? this.liveStyle,
      startTimeStyle: startTimeStyle ?? this.startTimeStyle,
      venueStyle: venueStyle ?? this.venueStyle,
      teamNameStyle: teamNameStyle ?? this.teamNameStyle,
      statusStyle: statusStyle ?? this.statusStyle,
      scoreStyle: scoreStyle ?? this.scoreStyle,
      versusStyle: versusStyle ?? this.versusStyle,
      liveChipStyle: liveChipStyle ?? this.liveChipStyle,
      messageStyle: messageStyle ?? this.messageStyle,
      listGap: listGap ?? this.listGap,
      filterChipStyle: filterChipStyle ?? this.filterChipStyle,
      filterHeaderColor: filterHeaderColor ?? this.filterHeaderColor,
      filterTrackColor: filterTrackColor ?? this.filterTrackColor,
      filterTrackBorder: filterTrackBorder ?? this.filterTrackBorder,
      filterSelectedStart: filterSelectedStart ?? this.filterSelectedStart,
      filterSelectedEnd: filterSelectedEnd ?? this.filterSelectedEnd,
      filterSelectedForeground:
          filterSelectedForeground ?? this.filterSelectedForeground,
      filterForeground: filterForeground ?? this.filterForeground,
      filterTrackHeight: filterTrackHeight ?? this.filterTrackHeight,
      filterUnderlineHeight:
          filterUnderlineHeight ?? this.filterUnderlineHeight,
      filterCapsuleMaxWidth:
          filterCapsuleMaxWidth ?? this.filterCapsuleMaxWidth,
      gridTileMinWidth: gridTileMinWidth ?? this.gridTileMinWidth,
    );
  }

  @override
  CricketScoreThemeData lerp(
    covariant ThemeExtension<CricketScoreThemeData>? other,
    double t,
  ) {
    if (other is! CricketScoreThemeData) return this;
    return CricketScoreThemeData(
      cardColor: Color.lerp(cardColor, other.cardColor, t),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      liveColor: Color.lerp(liveColor, other.liveColor, t),
      badgeBackground: Color.lerp(badgeBackground, other.badgeBackground, t),
      badgeForeground: Color.lerp(badgeForeground, other.badgeForeground, t),
      closeButtonBackground:
          Color.lerp(closeButtonBackground, other.closeButtonBackground, t),
      closeButtonBorder:
          Color.lerp(closeButtonBorder, other.closeButtonBorder, t),
      closeIconColor: Color.lerp(closeIconColor, other.closeIconColor, t),
      fabBorderColor: Color.lerp(fabBorderColor, other.fabBorderColor, t),
      liveChipColor: Color.lerp(liveChipColor, other.liveChipColor, t),
      liveChipForeground:
          Color.lerp(liveChipForeground, other.liveChipForeground, t),
      cardPadding: lerpDouble(cardPadding, other.cardPadding, t),
      outerPadding: lerpDouble(outerPadding, other.outerPadding, t),
      cardBorderRadius: lerpDouble(cardBorderRadius, other.cardBorderRadius, t),
      cardElevation: lerpDouble(cardElevation, other.cardElevation, t),
      closeButtonSize: lerpDouble(closeButtonSize, other.closeButtonSize, t),
      closeButtonOffset:
          lerpDouble(closeButtonOffset, other.closeButtonOffset, t),
      closeButtonBorderWidth:
          lerpDouble(closeButtonBorderWidth, other.closeButtonBorderWidth, t),
      logoRadius: lerpDouble(logoRadius, other.logoRadius, t),
      badgeRadius: lerpDouble(badgeRadius, other.badgeRadius, t),
      dividerHeight: lerpDouble(dividerHeight, other.dividerHeight, t),
      loadingCardSize: lerpDouble(loadingCardSize, other.loadingCardSize, t),
      smallHorizontalGap:
          lerpDouble(smallHorizontalGap, other.smallHorizontalGap, t),
      mediumHorizontalGap:
          lerpDouble(mediumHorizontalGap, other.mediumHorizontalGap, t),
      largeHorizontalGap:
          lerpDouble(largeHorizontalGap, other.largeHorizontalGap, t),
      smallVerticalGap: lerpDouble(smallVerticalGap, other.smallVerticalGap, t),
      mediumVerticalGap:
          lerpDouble(mediumVerticalGap, other.mediumVerticalGap, t),
      headerTrailingGap:
          lerpDouble(headerTrailingGap, other.headerTrailingGap, t),
      fabLogoRadius: lerpDouble(fabLogoRadius, other.fabLogoRadius, t),
      fabHeight: lerpDouble(fabHeight, other.fabHeight, t),
      fabBorderRadius: lerpDouble(fabBorderRadius, other.fabBorderRadius, t),
      fabElevation: lerpDouble(fabElevation, other.fabElevation, t),
      liveChipTop: lerpDouble(liveChipTop, other.liveChipTop, t),
      liveChipEnd: lerpDouble(liveChipEnd, other.liveChipEnd, t),
      fabPadding: EdgeInsetsGeometry.lerp(fabPadding, other.fabPadding, t),
      liveChipPadding:
          EdgeInsetsGeometry.lerp(liveChipPadding, other.liveChipPadding, t),
      matchTypeStyle: TextStyle.lerp(matchTypeStyle, other.matchTypeStyle, t),
      liveStyle: TextStyle.lerp(liveStyle, other.liveStyle, t),
      startTimeStyle: TextStyle.lerp(startTimeStyle, other.startTimeStyle, t),
      venueStyle: TextStyle.lerp(venueStyle, other.venueStyle, t),
      teamNameStyle: TextStyle.lerp(teamNameStyle, other.teamNameStyle, t),
      statusStyle: TextStyle.lerp(statusStyle, other.statusStyle, t),
      scoreStyle: TextStyle.lerp(scoreStyle, other.scoreStyle, t),
      versusStyle: TextStyle.lerp(versusStyle, other.versusStyle, t),
      liveChipStyle: TextStyle.lerp(liveChipStyle, other.liveChipStyle, t),
      messageStyle: TextStyle.lerp(messageStyle, other.messageStyle, t),
      listGap: lerpDouble(listGap, other.listGap, t),
      filterChipStyle:
          TextStyle.lerp(filterChipStyle, other.filterChipStyle, t),
      filterHeaderColor:
          Color.lerp(filterHeaderColor, other.filterHeaderColor, t),
      filterTrackColor: Color.lerp(filterTrackColor, other.filterTrackColor, t),
      filterTrackBorder:
          Color.lerp(filterTrackBorder, other.filterTrackBorder, t),
      filterSelectedStart:
          Color.lerp(filterSelectedStart, other.filterSelectedStart, t),
      filterSelectedEnd:
          Color.lerp(filterSelectedEnd, other.filterSelectedEnd, t),
      filterSelectedForeground: Color.lerp(
        filterSelectedForeground,
        other.filterSelectedForeground,
        t,
      ),
      filterForeground: Color.lerp(filterForeground, other.filterForeground, t),
      filterTrackHeight:
          lerpDouble(filterTrackHeight, other.filterTrackHeight, t),
      filterUnderlineHeight:
          lerpDouble(filterUnderlineHeight, other.filterUnderlineHeight, t),
      filterCapsuleMaxWidth:
          lerpDouble(filterCapsuleMaxWidth, other.filterCapsuleMaxWidth, t),
      gridTileMinWidth: lerpDouble(gridTileMinWidth, other.gridTileMinWidth, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CricketScoreThemeData &&
          other.cardColor == cardColor &&
          other.shadowColor == shadowColor &&
          other.accentColor == accentColor &&
          other.liveColor == liveColor &&
          other.badgeBackground == badgeBackground &&
          other.badgeForeground == badgeForeground &&
          other.closeButtonBackground == closeButtonBackground &&
          other.closeButtonBorder == closeButtonBorder &&
          other.closeIconColor == closeIconColor &&
          other.fabBorderColor == fabBorderColor &&
          other.liveChipColor == liveChipColor &&
          other.liveChipForeground == liveChipForeground &&
          other.cardPadding == cardPadding &&
          other.outerPadding == outerPadding &&
          other.cardBorderRadius == cardBorderRadius &&
          other.cardElevation == cardElevation &&
          other.closeButtonSize == closeButtonSize &&
          other.closeButtonOffset == closeButtonOffset &&
          other.closeButtonBorderWidth == closeButtonBorderWidth &&
          other.logoRadius == logoRadius &&
          other.badgeRadius == badgeRadius &&
          other.dividerHeight == dividerHeight &&
          other.loadingCardSize == loadingCardSize &&
          other.smallHorizontalGap == smallHorizontalGap &&
          other.mediumHorizontalGap == mediumHorizontalGap &&
          other.largeHorizontalGap == largeHorizontalGap &&
          other.smallVerticalGap == smallVerticalGap &&
          other.mediumVerticalGap == mediumVerticalGap &&
          other.headerTrailingGap == headerTrailingGap &&
          other.fabLogoRadius == fabLogoRadius &&
          other.fabHeight == fabHeight &&
          other.fabBorderRadius == fabBorderRadius &&
          other.fabElevation == fabElevation &&
          other.liveChipTop == liveChipTop &&
          other.liveChipEnd == liveChipEnd &&
          other.fabPadding == fabPadding &&
          other.liveChipPadding == liveChipPadding &&
          other.matchTypeStyle == matchTypeStyle &&
          other.liveStyle == liveStyle &&
          other.startTimeStyle == startTimeStyle &&
          other.venueStyle == venueStyle &&
          other.teamNameStyle == teamNameStyle &&
          other.statusStyle == statusStyle &&
          other.scoreStyle == scoreStyle &&
          other.versusStyle == versusStyle &&
          other.liveChipStyle == liveChipStyle &&
          other.messageStyle == messageStyle &&
          other.listGap == listGap &&
          other.filterChipStyle == filterChipStyle &&
          other.filterHeaderColor == filterHeaderColor &&
          other.filterTrackColor == filterTrackColor &&
          other.filterTrackBorder == filterTrackBorder &&
          other.filterSelectedStart == filterSelectedStart &&
          other.filterSelectedEnd == filterSelectedEnd &&
          other.filterSelectedForeground == filterSelectedForeground &&
          other.filterForeground == filterForeground &&
          other.filterTrackHeight == filterTrackHeight &&
          other.filterUnderlineHeight == filterUnderlineHeight &&
          other.filterCapsuleMaxWidth == filterCapsuleMaxWidth &&
          other.gridTileMinWidth == gridTileMinWidth;

  @override
  int get hashCode => Object.hashAll([
        cardColor,
        shadowColor,
        accentColor,
        liveColor,
        badgeBackground,
        badgeForeground,
        closeButtonBackground,
        closeButtonBorder,
        closeIconColor,
        fabBorderColor,
        liveChipColor,
        liveChipForeground,
        cardPadding,
        outerPadding,
        cardBorderRadius,
        cardElevation,
        closeButtonSize,
        closeButtonOffset,
        closeButtonBorderWidth,
        logoRadius,
        badgeRadius,
        dividerHeight,
        loadingCardSize,
        smallHorizontalGap,
        mediumHorizontalGap,
        largeHorizontalGap,
        smallVerticalGap,
        mediumVerticalGap,
        headerTrailingGap,
        fabLogoRadius,
        fabHeight,
        fabBorderRadius,
        fabElevation,
        liveChipTop,
        liveChipEnd,
        fabPadding,
        liveChipPadding,
        matchTypeStyle,
        liveStyle,
        startTimeStyle,
        venueStyle,
        teamNameStyle,
        statusStyle,
        scoreStyle,
        versusStyle,
        liveChipStyle,
        messageStyle,
        listGap,
        filterChipStyle,
        filterHeaderColor,
        filterTrackColor,
        filterTrackBorder,
        filterSelectedStart,
        filterSelectedEnd,
        filterSelectedForeground,
        filterForeground,
        filterTrackHeight,
        filterUnderlineHeight,
        filterCapsuleMaxWidth,
        gridTileMinWidth,
      ]);
}
