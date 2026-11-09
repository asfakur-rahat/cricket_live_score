import 'package:flutter/widgets.dart' show StringCharacters;

/// Words left off the end of a name: `India A`, `Afghanistan U19`.
final _qualifier =
    RegExp(r'^(a|b|w|xi|women|men|u\d{2}|under\d{2})$', caseSensitive: false);

/// Words that join a name's parts: `United States of America`.
const _joining = {'of', 'and', 'the'};

/// Anything that isn't a letter, a digit or a combining mark.
final _punctuation = RegExp(r'[^\p{L}\p{M}\p{N}]', unicode: true);

/// The initials of a team [name]; see `TeamInfo.initials`.
String teamInitials(String name) {
  final words = [
    for (final word in name.trim().split(RegExp(r'\s+')))
      if (word.replaceAll(_punctuation, '') case final clean
          when clean.isNotEmpty)
        clean,
  ];
  while (words.length > 1 && _qualifier.hasMatch(words.last)) {
    words.removeLast();
  }
  final main = [
    for (final word in words)
      if (!_joining.contains(word.toLowerCase())) word,
  ];
  final kept = main.isEmpty ? words : main;
  if (kept.isEmpty) return '?';

  if (kept.length == 1) {
    final word = kept.single;
    final length = word.characters.length;
    final capitals = word == word.toUpperCase() && word != word.toLowerCase();
    if (capitals && length >= 2 && length <= 4) return word;
    return word.characters.take(3).toString().toUpperCase();
  }
  return [
    for (final word in kept.take(3)) word.characters.first.toUpperCase(),
  ].join();
}
