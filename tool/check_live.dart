// A canary against texttv.nu changing its markup: reads a handful of live
// pages through the app's own client and fails if any can no longer be read
// with its colours (the app would quietly fall back to plain text).
//
//   dart run tool/check_live.dart [page ...]
//
// Polite by design: a few pages, one second apart, the app's own `app` id.
// Run by `.github/workflows/live-canary.yml` once a week, not on every push.
import 'dart:io';

import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/services/io_http_fetcher.dart';
import 'package:codedbykay_text_tv/services/network_exception.dart';
import 'package:codedbykay_text_tv/services/text_tv.dart';

/// Pages that are always in broadcast: news, home and foreign news, sport,
/// the page with the block-graphics header, weather and the index.
const List<int> _defaultPages = <int>[100, 101, 104, 300, 377, 400, 700];

Future<void> main(List<String> args) async {
  final List<int> pages = args.isEmpty
      ? _defaultPages
      : <int>[for (final String a in args) int.parse(a)];
  final TextTv client = TextTv(fetcher: IoHttpFetcher());
  int bad = 0;
  for (final int number in pages) {
    String verdict;
    try {
      final TextTvPage? page = await client.page(number);
      if (page == null) {
        verdict = 'NOT IN BROADCAST (unexpected for a page we rely on)';
        bad++;
      } else if (page.styledParts == null) {
        verdict = 'FALLBACK: read as plain text, colours lost';
        bad++;
      } else {
        verdict = 'ok (${page.parts.length} part(s), coloured)';
      }
    } on NetworkException catch (error) {
      verdict = 'FAILED: ${error.message}';
      bad++;
    }
    stdout.writeln('$number: $verdict');
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  if (bad > 0) {
    stderr.writeln('$bad of ${pages.length} pages did not read as expected.');
    exit(1);
  }
  stdout.writeln('All ${pages.length} pages read with their colours.');
}
