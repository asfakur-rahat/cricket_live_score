import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/models/match_phase.dart';
import 'package:flutter/foundation.dart';

/// Which matches to show, by match type and by [MatchPhase].
///
/// An empty set means every value is allowed, so the default filter lets
/// every match through. A match must pass both sets.
@immutable
class CricketMatchFilter {
  /// Creates a filter.
  const CricketMatchFilter({this.types = const {}, this.phases = const {}});

  /// The filter that lets every match through.
  static const all = CricketMatchFilter();

  /// Match types to keep, for example `{'T20', 'ODI'}`, compared ignoring
  /// case; empty keeps every type.
  final Set<String> types;

  /// Phases to keep; empty keeps every phase.
  final Set<MatchPhase> phases;

  /// Whether this filter lets every match through.
  bool get isAll => types.isEmpty && phases.isEmpty;

  /// Whether [match] passes this filter.
  bool accepts(CricketMatch match) {
    if (phases.isNotEmpty && !phases.contains(match.phase)) return false;
    if (types.isEmpty) return true;
    final type = match.matchType.toUpperCase();
    return types.any((t) => t.toUpperCase() == type);
  }

  /// Returns a copy of this filter with the given sets replaced.
  CricketMatchFilter copyWith({
    Set<String>? types,
    Set<MatchPhase>? phases,
  }) {
    return CricketMatchFilter(
      types: types ?? this.types,
      phases: phases ?? this.phases,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CricketMatchFilter &&
          setEquals(other.types, types) &&
          setEquals(other.phases, phases);

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(types),
        Object.hashAllUnordered(phases),
      );

  @override
  String toString() => 'CricketMatchFilter(types: $types, phases: $phases)';
}

/// The matches that pass [filter], in their original order.
List<CricketMatch> filterMatches(
  List<CricketMatch> matches,
  CricketMatchFilter filter,
) {
  if (filter.isAll) return matches;
  return [
    for (final match in matches)
      if (filter.accepts(match)) match,
  ];
}

// The common formats come first, in this order; anything else follows
// alphabetically.
const _typeOrder = ['T20', 'ODI', 'TEST', 'T10'];

/// The distinct match types in [matches], in upper case, for building filter
/// choices.
///
/// T20, ODI, TEST and T10 come first, in that order, followed by any other
/// type alphabetically. Empty types are left out.
List<String> matchTypesOf(List<CricketMatch> matches) {
  final types = {
    for (final match in matches)
      if (match.matchType.trim().isNotEmpty)
        match.matchType.trim().toUpperCase(),
  };
  int rank(String type) {
    final index = _typeOrder.indexOf(type);
    return index == -1 ? _typeOrder.length : index;
  }

  return types.toList()
    ..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.compareTo(b);
    });
}
