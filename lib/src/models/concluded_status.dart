/// Words in a status line that mean the match is over.
const _concludedWords = ['won', 'tied', 'drawn', 'no result', 'abandoned'];

/// Whether [status] reports a result: won, tied, drawn, no result or
/// abandoned.
bool isConcludedStatus(String status) {
  final lowerStatus = status.toLowerCase();
  return _concludedWords.any(lowerStatus.contains);
}
