import 'package:cricket_live_score/src/models/cricket_match.dart';

/// Supplies the list of matches shown by the package's widgets.
///
/// Implement this to show scores from your own backend or a keyed API.
// An interface rather than a function type, so implementations can carry
// their own configuration and lifecycle.
// ignore: one_member_abstracts
abstract interface class CricketScoreSource {
  /// Fetches the current matches, in the order the source returns them.
  ///
  /// Throws a [CricketScoreException] when the matches cannot be fetched or
  /// parsed.
  Future<List<CricketMatch>> fetchMatches();
}

/// Thrown by a [CricketScoreSource] when matches cannot be fetched or parsed.
class CricketScoreException implements Exception {
  /// Creates an exception with a human-readable [message].
  const CricketScoreException(this.message, {this.statusCode, this.cause});

  /// What went wrong.
  final String message;

  /// HTTP status code of the failed response, when there was one.
  final int? statusCode;

  /// The underlying error, when there was one.
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('CricketScoreException: $message');
    if (statusCode != null) buffer.write(' (HTTP $statusCode)');
    if (cause != null) buffer.write(': $cause');
    return buffer.toString();
  }
}
