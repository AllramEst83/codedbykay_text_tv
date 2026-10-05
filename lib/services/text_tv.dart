import 'dart:convert';

import 'package:codedbykay_text_tv/model/network_failure.dart';
import 'package:codedbykay_text_tv/model/styled_text.dart';
import 'package:codedbykay_text_tv/model/text_tv_html.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/http_fetcher.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';

/// SVT Text through the public texttv.nu API
/// (https://texttv.nu/blogg/texttv-api). Read-only.
class TextTv {
  TextTv({required this._fetcher, this._app = 'texttv_android'});

  final HttpFetcher _fetcher;

  /// The API asks every client to identify itself with a unique `app` value.
  final String _app;

  /// The page, or null when it is not in broadcast. Throws [NetworkException]
  /// when the site cannot be reached or answers with something unexpected.
  Future<TextTvPage?> page(int number) async =>
      parse(number, await fetchBody(number));

  /// The site's raw answer for page [number]; [parse] reads it. Split from
  /// [page] so an answer can be kept as it came and read again later.
  Future<String> fetchBody(int number) {
    final url = Uri.https('texttv.nu', '/api/get/$number', {
      'app': _app,
      'includePlainTextContent': '1',
    });
    return _fetcher.get(url);
  }

  /// Whether the site has a newer version of [number] than the one changed at
  /// [sinceUnix] (the time its answer gave, `TextTvPage.updatedUnix`). One small
  /// request, a few hundred bytes, in place of reading the page. Throws
  /// [NetworkException] when the site cannot be reached or answers with
  /// something unexpected.
  Future<bool> hasUpdate(int number, int sinceUnix) async {
    final url = Uri.https('texttv.nu', '/api/updated/$number/$sinceUnix', {
      'app': _app,
    });
    final Object? json;
    try {
      json = jsonDecode(await _fetcher.get(url));
    } on FormatException {
      throw _unexpected;
    }
    if (json is! Map || json['update_available'] is! bool) throw _unexpected;
    return json['update_available'] as bool;
  }

  /// Reads an answer from [fetchBody]: the page, or null when it is not in
  /// broadcast. Throws [NetworkException] when it is not what the site sends.
  TextTvPage? parse(int number, String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      throw _unexpected;
    }
    if (json is! List) throw _unexpected;
    // An unknown page number is answered with an empty list.
    if (json.isEmpty) return null;

    final page = json.first;
    if (page is! Map) throw _unexpected;
    final plain = page['content_plain'];
    if (plain is! List || plain.isEmpty || plain.any((p) => p is! String)) {
      throw _unexpected;
    }

    final parts = [
      for (final part in plain.cast<String>())
        [for (final line in part.split('\n')) line.trimRight()],
    ];
    if (_notBroadcast(parts)) return null;
    return TextTvPage(
      number: number,
      parts: parts,
      styledParts: _styled(page['content'], parts.length),
      previous: _pageNumber(page['prev_page']),
      next: _pageNumber(page['next_page']),
      updatedUnix: _int(page['date_updated_unix']),
      id: _text(page['id']),
      permalink: _link(page['permalink']),
      breadcrumbs: _crumbs(page['breadcrumbs']),
    );
  }

  /// The coloured version of every part, or null if any part cannot be read
  /// (all or nothing, so a page is never half colour). The plain text stays
  /// the source of truth.
  List<List<List<StyledRun>>>? _styled(Object? content, int parts) {
    if (content is! List || content.length != parts) return null;
    final styled = <List<List<StyledRun>>>[];
    for (final html in content) {
      if (html is! String) return null;
      final rows = parseTextTvHtml(
        html,
        columns: textTvColumns,
        commandFor: (page) => '$page',
      );
      if (rows == null) return null;
      styled.add(rows);
    }
    return styled;
  }

  /// A page that is not in broadcast comes back as one line saying so.
  bool _notBroadcast(List<List<String>> parts) {
    return parts.length == 1 &&
        parts.single.length == 1 &&
        parts.single.single.toLowerCase().contains('ej i sändning');
  }

  int? _pageNumber(Object? value) => int.tryParse('$value');

  int? _int(Object? value) => value == null ? null : int.tryParse('$value');

  String? _text(Object? value) {
    final String? text = value == null ? null : '$value'.trim();
    return text == null || text.isEmpty ? null : text;
  }

  /// A link of the site's own, nothing else: what the answer names as a link is
  /// shared with others, so it is not taken on trust.
  String? _link(Object? value) {
    final String? text = _text(value);
    final Uri? uri = text == null ? null : Uri.tryParse(text);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.endsWith('texttv.nu')
        ? text
        : null;
  }

  List<Crumb>? _crumbs(Object? value) {
    if (value is! List) return null;
    final List<Crumb> crumbs = <Crumb>[
      for (final Object? entry in value)
        if (entry is Map)
          if (_pageNumber(entry['num']) case final int page
              when page >= textTvFirstPage && page <= textTvLastPage)
            Crumb('${entry['name'] ?? ''}'.trim(), page),
    ];
    return crumbs.isEmpty ? null : crumbs;
  }

  NetworkException get _unexpected => const NetworkException(
    'texttv.nu sent an answer I could not read',
    failure: NetworkFailure.changed,
  );
}
