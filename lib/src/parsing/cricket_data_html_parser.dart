import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/models/team_info.dart';
import 'package:cricket_live_score/src/models/team_score.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Parses the HTML of cricketdata.org's website score widget into
/// [CricketMatch] values.
abstract final class CricketDataHtmlParser {
  /// Image used when a team has no logo.
  static const defaultFlag =
      'https://p7.hiclipart.com/preview/819/757/139/flag-computer-icons-pictogram-clip-art-green-flags-icon-png.jpg';

  /// Parses the HTML of a single match slab.
  static CricketMatch parse(String htmlString) {
    final document = html_parser.parse(htmlString);

    final matchId = _extractMatchId(document);
    final matchType = _extractMatchType(document);
    final dateTime = _extractDateTime(document);
    final venue = _extractVenue(document);
    final status = _extractStatus(document);
    final fullScorecardUrl = _extractFullScorecardUrl(document);

    // Extract teams info with scores
    final teams = _extractTeams(document, status);

    final teamScores = _extractTeamScores(document);

    final isLive = _extractIsLive(document);

    return CricketMatch(
      id: matchId,
      matchType: matchType,
      startTimeText: dateTime,
      venue: venue,
      status: status,
      team1: teams.isNotEmpty
          ? teams[0]
          : const TeamInfo(name: 'Team 1', logoUrl: ''),
      team2: teams.length > 1
          ? teams[1]
          : const TeamInfo(name: 'Team 2', logoUrl: ''),
      fullScorecardUrl: fullScorecardUrl,
      teamScores: teamScores,
      isLive: isLive,
    );
  }

  /// Parses every `.slab` match in [htmlString].
  ///
  /// A slab that fails to parse is skipped.
  static List<CricketMatch> parseMultiple(String htmlString) {
    final document = html_parser.parse(htmlString);
    final slabDivs = document.querySelectorAll('.slab');

    final matches = <CricketMatch>[];

    for (final slabDiv in slabDivs) {
      try {
        final matchHtml = slabDiv.outerHtml;
        final match = parse(matchHtml);
        matches.add(match);
      } on Object catch (e) {
        if (kDebugMode) {
          print('Error parsing match: $e');
        }
        continue;
      }
    }

    return matches;
  }

  static String _extractMatchId(Document document) {
    final slabDiv = document.querySelector('.slab');
    return slabDiv?.attributes['data-id'] ?? '';
  }

  static String _extractMatchType(Document document) {
    final matchTypeSpan =
        document.querySelector('span[style*="position: absolute"]');
    return matchTypeSpan?.text.trim().toUpperCase() ?? '';
  }

  static bool _extractIsLive(Document document) {
    // The upstream widget embeds a red "LIVE" span in every slab regardless of
    // actual state, so it can't be trusted. Treat a match as live only when
    // the score table has rows and the status doesn't indicate a concluded
    // result (won / tied / drawn / abandoned / no result).
    final scoreTable = document.querySelector('table');
    final hasScoreRows = scoreTable?.querySelectorAll('tr').isNotEmpty ?? false;
    if (!hasScoreRows) return false;

    final status = _extractStatus(document).toLowerCase();
    const concluded = ['won', 'tied', 'drawn', 'no result', 'abandoned'];
    return !concluded.any(status.contains);
  }

  // Matches "19 Jul 2026, Sun 10:00 GMT" (day can be 1 or 2 digits).
  static final _dateTimeRegExp = RegExp(
    r'\d{1,2}\s+\w{3}\s+\d{4},\s+\w{3}\s+\d{1,2}:\d{2}\s+GMT',
  );

  static String _extractDateTime(Document document) {
    for (final div in document.querySelectorAll('div')) {
      final match = _dateTimeRegExp.firstMatch(div.text);
      if (match != null) {
        return match.group(0)!;
      }
    }
    return '';
  }

  static String _extractVenue(Document document) {
    final venueElement = document.querySelector('b');
    return venueElement?.text.trim() ?? '';
  }

  static String _extractStatus(Document document) {
    // Find all hr elements
    final hrElements = document.querySelectorAll('hr');

    // The status is typically after the second <hr>
    if (hrElements.length >= 2) {
      var nextElement = hrElements[1].nextElementSibling;

      // Find the next div that contains status text
      while (nextElement != null) {
        if (nextElement.localName == 'div') {
          final text = nextElement.text.trim();

          // Check if this is a status div (not team info, not empty)
          if (text.isNotEmpty &&
              !text.contains('«') &&
              !text.contains('»') &&
              !text.contains('Full Scorecard') &&
              !text.contains('Get this Widget') &&
              text.length < 200) {
            return text;
          }
        }
        nextElement = nextElement.nextElementSibling;
      }
    }

    return '';
  }

  static String? _extractFullScorecardUrl(Document document) {
    final links = document.querySelectorAll('a');
    for (final link in links) {
      final onclick = link.attributes['onclick'] ?? '';
      if (onclick.contains('showModal')) {
        final urlMatch = RegExp(r"showModal\('([^']+)'\)").firstMatch(onclick);
        if (urlMatch != null) {
          return urlMatch.group(1);
        }
      }
    }
    return null;
  }

  static List<TeamScore> _extractTeamScores(Document document) {
    // First, try to extract scores from table
    final scoreTable = document.querySelector('table');
    final scoreRows = scoreTable?.querySelectorAll('tr') ?? [];
    final teamScores = <TeamScore>[];

    for (final row in scoreRows) {
      final cells = row.querySelectorAll('td');
      if (cells.length >= 2) {
        final teamName = cells[0].text.trim();
        final scoreText = cells[1].text.trim();
        teamScores.add(TeamScore(teamName: teamName, scoreText: scoreText));
      }
    }
    return teamScores;
  }

  static List<TeamInfo> _extractTeams(Document document, String status) {
    final teams = <TeamInfo>[];

    // First, try to extract scores from table
    final scoreTable = document.querySelector('table');
    final scoreRows = scoreTable?.querySelectorAll('tr') ?? [];
    final teamScores = <TeamScore>[];

    for (final row in scoreRows) {
      final cells = row.querySelectorAll('td');
      if (cells.length >= 2) {
        final teamName = cells[0].text.trim();
        final scoreText = cells[1].text.trim();
        teamScores.add(TeamScore(teamName: teamName, scoreText: scoreText));
      }
    }

    // Try to find team divs (both formats)
    final allDivs = document.querySelectorAll('div');

    // Format 1: divs with display:table-cell and width:50%
    final tableCellDivs = allDivs.where((div) {
      final style = div.attributes['style'] ?? '';
      return style.contains('display:table-cell') &&
          style.contains('width:50%') &&
          !style.contains('width:2em'); // Exclude the 'v' separator
    }).toList();

    if (tableCellDivs.isNotEmpty) {
      var index = 0;
      for (final teamDiv in tableCellDivs) {
        teams.add(_parseTeamDiv(teamDiv, status, index));
        index++;
      }
    } else {
      // Format 2: divs with white-space: nowrap
      final whitespaceDivs = allDivs.where((div) {
        final style = div.attributes['style'] ?? '';
        return style.contains('white-space: nowrap') &&
            style.contains('overflow: hidden') &&
            style.contains('padding: 5px');
      }).toList();

      var index = 0;
      for (final teamDiv in whitespaceDivs) {
        final teamName = _extractTeamName(teamDiv);
        if (teamName.isEmpty || teamName == 'v') continue;

        teams.add(_parseTeamDiv(teamDiv, status, index));
        index++;
      }
    }

    // If no teams found, try to get them from score table directly
    if (teams.isEmpty && teamScores.isNotEmpty) {
      for (final scoreData in teamScores.take(2)) {
        final isWinner = _isWinner(scoreData.teamName, status);
        teams.add(
          TeamInfo(
            name: scoreData.teamName,
            logoUrl: '',
            isWinner: isWinner,
          ),
        );
      }
    }

    // Fallback
    if (teams.isEmpty) {
      return [
        const TeamInfo(name: 'Team 1', logoUrl: ''),
        const TeamInfo(name: 'Team 2', logoUrl: ''),
      ];
    }

    // Ensure exactly 2 teams
    if (teams.length < 2) {
      teams.add(const TeamInfo(name: 'Unknown Team', logoUrl: ''));
    }

    return teams.take(2).toList();
  }

  static TeamInfo _parseTeamDiv(
    Element teamDiv,
    String status,
    int index,
  ) {
    final img = teamDiv.querySelector('img');
    final logoUrl = img?.attributes['src'] ?? '';
    final teamName = _extractTeamName(teamDiv);

    final isWinner = _isWinner(teamName, status);

    return TeamInfo(
      name: teamName,
      logoUrl: logoUrl,
      isWinner: isWinner,
    );
  }

  static String _extractTeamName(Element teamDiv) {
    // Get all text and clean it
    var text = teamDiv.text.trim();

    // Remove stars and bold markers
    text = text.replaceAll('⭐', '').trim();

    // If there's a <b> tag, prefer its content
    final boldElement = teamDiv.querySelector('b');
    if (boldElement != null) {
      text = boldElement.text.trim();
    }

    return text;
  }

  static bool _isWinner(String teamName, String status) {
    // Check if team name appears with star markers or in status
    return status.contains('⭐') && status.contains(teamName) ||
        status.toLowerCase().contains(teamName.toLowerCase()) &&
            status.toLowerCase().contains('won');
  }
}
