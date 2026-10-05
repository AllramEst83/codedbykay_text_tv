import 'dart:async';

import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/page_search.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// Opens a search over the pages already read, for finding a page by a word
/// in it. A number that is a page offers going straight there. [search] does
/// the finding; [onOpen] is told the page chosen, after the sheet has closed.
Future<void> showSearchSheet(
  BuildContext context, {
  required Future<List<SearchHit>> Function(String query) search,
  required ValueChanged<int> onOpen,
  Duration wait = const Duration(milliseconds: 250),
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TvColors.black,
    barrierColor: Colors.black38,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (BuildContext sheet) => _SearchSheet(
      search: search,
      wait: wait,
      onOpen: (int page) {
        Navigator.of(sheet).pop();
        onOpen(page);
      },
    ),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({
    required this.search,
    required this.wait,
    required this.onOpen,
  });

  final Future<List<SearchHit>> Function(String query) search;
  final Duration wait;
  final ValueChanged<int> onOpen;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  int _asked = 0;
  String _query = '';
  List<SearchHit> _hits = const <SearchHit>[];

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _timer?.cancel();
    final int ask = ++_asked;
    setState(() {
      _query = text.trim();
      if (_query.length < minSearchLength) _hits = const <SearchHit>[];
    });
    if (_query.length < minSearchLength) return;
    final String query = _query;
    _timer = Timer(widget.wait, () async {
      final List<SearchHit> hits = await widget.search(query);
      // A later keystroke has started a newer search: this answer is stale.
      if (mounted && ask == _asked) setState(() => _hits = hits);
    });
  }

  int? get _asPage {
    final int? number = int.tryParse(_query);
    return _query.length == 3 &&
            number != null &&
            number >= textTvFirstPage &&
            number <= textTvLastPage
        ? number
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final int? goTo = _asPage;
    final bool searched = _query.length >= minSearchLength;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: TvColors.border, width: TvMetrics.border),
            ),
          ),
          padding: const EdgeInsets.all(TvMetrics.margin),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(Messages.searchTitle, style: tvText(12, TvColors.white)),
              const SizedBox(height: TvMetrics.margin),
              TextField(
                key: textTvSearchFieldKey,
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: tvText(12, TvColors.white),
                cursorColor: TvColors.highlight,
                onChanged: _changed,
                onSubmitted: (String _) {
                  if (goTo != null) {
                    widget.onOpen(goTo);
                  } else if (_hits.isNotEmpty) {
                    widget.onOpen(_hits.first.page);
                  }
                },
                decoration: InputDecoration(
                  hintText: Messages.searchHint,
                  hintStyle: tvText(10, TvColors.dim),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(TvMetrics.gutter),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: TvColors.white,
                      width: TvMetrics.border,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: TvColors.highlight,
                      width: TvMetrics.border,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TvMetrics.gutter),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    if (goTo != null)
                      _Row(
                        key: textTvSearchGoKey,
                        label: Messages.searchGo(goTo),
                        semantics: Messages.pageLabel(goTo),
                        onTap: () => widget.onOpen(goTo),
                      ),
                    for (final SearchHit hit in _hits)
                      _Row(
                        key: textTvSearchHitKey(hit.page),
                        label: '${hit.page}  ${hit.line}',
                        semantics:
                            '${Messages.pageLabel(hit.page)}. ${hit.line}',
                        onTap: () => widget.onOpen(hit.page),
                      ),
                    if (searched && goTo == null && _hits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: TvMetrics.gutter,
                        ),
                        child: Text(
                          Messages.searchNothing,
                          key: textTvSearchEmptyKey,
                          style: tvText(10, TvColors.dim),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: TvMetrics.gutter),
              Text(Messages.searchScope, style: tvText(8, TvColors.dim)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: TvMetrics.gutter),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: TvColors.border, width: 1),
            ),
          ),
          child: Text(
            label,
            style: tvText(10, TvColors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
