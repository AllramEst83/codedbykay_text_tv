import 'package:codedbykay_text_tv/model/text_tv_page.dart';

/// The link the home-screen widget opens the app with, for [page]:
/// `texttv://page/377`.
Uri launchLinkFor(int page) =>
    Uri(scheme: 'texttv', host: 'page', path: '/$page');

/// The page a launch link stands for, or null for anything that is not one of
/// ours or not a page.
int? pageOfLaunchLink(Uri? link) {
  if (link == null || link.scheme != 'texttv' || link.host != 'page') {
    return null;
  }
  final List<String> segments = link.pathSegments;
  if (segments.length != 1) return null;
  final int? page = int.tryParse(segments.single);
  if (page == null || page < textTvFirstPage || page > textTvLastPage) {
    return null;
  }
  return page;
}
