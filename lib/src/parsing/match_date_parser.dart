const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

// "19 Jul 2026, Sun 10:00 GMT" — the weekday is ignored.
final _startTimeRegExp = RegExp(
  r'^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4}),\s+[A-Za-z]{3}\s+(\d{1,2}):(\d{2})\s+GMT$',
);

/// Parses a start time such as `"19 Jul 2026, Sun 10:00 GMT"` into a UTC
/// [DateTime].
///
/// Returns `null` when [text] is not in that format or names an impossible
/// date or time (for example `"31 Feb"` or `"25:00"`).
DateTime? parseMatchStartTime(String text) {
  final match = _startTimeRegExp.firstMatch(text.trim());
  if (match == null) return null;

  final day = int.parse(match.group(1)!);
  final month = _months[match.group(2)!.toLowerCase()];
  final year = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  if (month == null || hour > 23 || minute > 59) return null;

  final result = DateTime.utc(year, month, day, hour, minute);
  // DateTime.utc rolls 31 Feb over into March; reject instead.
  if (result.month != month || result.day != day) return null;
  return result;
}
