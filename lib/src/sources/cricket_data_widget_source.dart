import 'dart:async';
import 'dart:convert';

import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/parsing/cricket_data_html_parser.dart';
import 'package:cricket_live_score/src/selection/match_sorting.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:http/http.dart' as http;

/// Reads matches from cricketdata.org's embeddable website score widget.
///
/// The default [referrer] is used with cricketdata.org's permission. This
/// reads the HTML the widget serves, not a documented API, so it can break
/// when the upstream markup changes.
class CricketDataWidgetSource implements CricketScoreSource {
  /// Creates a source that sends [referrer] as the widget's `r` parameter.
  ///
  /// [referrer] defaults to [defaultReferrer]; pass the URL of the page you
  /// embed the widget on if cricketdata.org gave you a different one.
  ///
  /// Pass a [client] to control HTTP (for example in tests); otherwise the
  /// source creates one and [close] closes it. [endpoint] overrides the
  /// widget URL. [onLog] receives debug messages. A request that takes
  /// longer than [timeout] fails with a [CricketScoreException].
  CricketDataWidgetSource({
    this.referrer = defaultReferrer,
    http.Client? client,
    Uri? endpoint,
    this.onLog,
    this.timeout = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        endpoint = endpoint ?? defaultEndpoint;

  /// The referrer used when none is given, sent percent-encoded as
  /// `r=https%3A%2F%2Fcricketdata.org%2Fwidgets-for-your-website-blog%2F`.
  static const defaultReferrer =
      'https://cricketdata.org/widgets-for-your-website-blog/';

  /// The widget URL used when no `endpoint` is given.
  static final Uri defaultEndpoint = Uri.parse(
    'https://cricketdata.org/apis/prepscores.aspx',
  );

  /// URL of the page the widget is embedded on, sent as the `r` parameter.
  final String referrer;

  /// The widget URL requests are sent to.
  final Uri endpoint;

  /// Receives debug messages, or `null` to stay silent.
  final void Function(String message)? onLog;

  /// How long a single request may take.
  final Duration timeout;

  final http.Client _client;
  final bool _ownsClient;

  /// The URL [fetchMatches] requests at [now].
  ///
  /// `k` changes every five seconds so caches between the app and the widget
  /// server cannot serve a stale score for longer than that.
  Uri requestUri(DateTime now) => endpoint.replace(
        queryParameters: {
          ...endpoint.queryParameters,
          'k': '${now.millisecondsSinceEpoch ~/ 5000}',
          'r': referrer,
        },
      );

  /// Fetches the widget's matches, ordered with [sortMatches].
  @override
  Future<List<CricketMatch>> fetchMatches() async {
    final http.Response response;
    try {
      response = await _client.get(requestUri(DateTime.now())).timeout(timeout);
    } on TimeoutException catch (e) {
      throw CricketScoreException('Request timed out', cause: e);
    } on Exception catch (e) {
      throw CricketScoreException('Request failed', cause: e);
    }

    onLog?.call('response: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw CricketScoreException(
        'Unexpected response',
        statusCode: response.statusCode,
      );
    }

    try {
      final html = utf8.decode(response.bodyBytes, allowMalformed: true);
      return sortMatches(
        CricketDataHtmlParser.parseMultiple(html, onLog: onLog),
      );
    } on Object catch (e) {
      throw CricketScoreException('Could not parse the response', cause: e);
    }
  }

  /// Closes the HTTP client if this source created it.
  ///
  /// A client passed to the constructor is left open for its owner to close.
  void close() {
    if (_ownsClient) _client.close();
  }
}
