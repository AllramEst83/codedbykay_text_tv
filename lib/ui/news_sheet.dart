import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:codedbykay_text_tv/model/feed.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:codedbykay_text_tv/ui/tv_option_rows.dart';
import 'package:flutter/material.dart';

/// Opens what is new over the page: the news and sport pages changed last, and
/// the pages read most today, three lists to pick between and a page in each
/// to open. [feed] gives a list (null when there is none to give); [onOpen] is
/// told the page chosen, after the sheet has closed.
Future<void> showNewsSheet(
  BuildContext context, {
  required Future<List<FeedItem>?> Function(FeedKind kind) feed,
  required ValueChanged<int> onOpen,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TvColors.black,
    barrierColor: Colors.black38,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (BuildContext sheet) => _NewsSheet(
      feed: feed,
      onOpen: (int page) {
        Navigator.of(sheet).pop();
        onOpen(page);
      },
    ),
  );
}

class _NewsSheet extends StatefulWidget {
  const _NewsSheet({required this.feed, required this.onOpen});

  final Future<List<FeedItem>?> Function(FeedKind kind) feed;
  final ValueChanged<int> onOpen;

  @override
  State<_NewsSheet> createState() => _NewsSheetState();
}

class _NewsSheetState extends State<_NewsSheet> {
  FeedKind _kind = FeedKind.latestNews;
  bool _loading = true;
  List<FeedItem>? _items;
  // The list asked for last: an answer for another one came too late.
  int _asked = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final int ask = ++_asked;
    setState(() => _loading = true);
    final List<FeedItem>? items = await widget.feed(_kind);
    if (!mounted || ask != _asked) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _choose(FeedKind kind) {
    if (kind == _kind) return;
    _kind = kind;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final List<FeedItem>? items = _items;
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: TvColors.border, width: TvMetrics.border),
          ),
        ),
        padding: const EdgeInsets.all(TvMetrics.margin),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(context.l10n.newsTitle, style: tvText(12, TvColors.white)),
            const SizedBox(height: TvMetrics.margin),
            Row(
              children: <Widget>[
                for (final FeedKind kind in FeedKind.values)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: kind == FeedKind.values.last
                            ? 0
                            : TvMetrics.gutter,
                      ),
                      child: TvChoice(
                        choiceKey: textTvFeedKindKey(kind),
                        label: context.l10n.feedName(kind),
                        selected: _kind == kind,
                        onTap: () => _choose(kind),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TvMetrics.gutter),
            Flexible(
              child: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(TvMetrics.margin),
                      child: Text(
                        context.l10n.loading,
                        style: tvText(10, TvColors.dim),
                      ),
                    )
                  : items == null
                  ? _Message(
                      key: textTvFeedFailedKey,
                      text: context.l10n.feedFailed,
                      retry: _load,
                    )
                  : items.isEmpty
                  ? _Message(
                      key: textTvFeedEmptyKey,
                      text: context.l10n.feedEmpty,
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        for (final FeedItem item in items)
                          _Row(
                            item: item,
                            onTap: () => widget.onOpen(item.page),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: TvMetrics.gutter),
            Text(context.l10n.feedHint, style: tvText(8, TvColors.dim)),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text, this.retry});

  final String text;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TvMetrics.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(text, style: tvText(10, TvColors.white)),
          if (retry != null) ...<Widget>[
            const SizedBox(height: TvMetrics.gutter),
            TvButton(
              key: textTvRetryKey,
              label: context.l10n.tryAgain,
              onTap: retry,
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.onTap});

  final FeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? time = item.time;
    return Semantics(
      button: true,
      label:
          '${item.title}. ${context.l10n.pageLabel(item.page)}'
          '${time == null ? '' : '. $time'}',
      excludeSemantics: true,
      child: InkWell(
        key: textTvFeedItemKey(item.page),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: TvMetrics.gutter,
            vertical: 6,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: TvColors.border, width: 1),
            ),
          ),
          child: Row(
            children: <Widget>[
              Text('${item.page}', style: tvText(10, TvColors.highlight)),
              const SizedBox(width: TvMetrics.gutter),
              Expanded(
                child: Text(
                  item.title,
                  style: tvText(10, TvColors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (time != null) ...<Widget>[
                const SizedBox(width: TvMetrics.gutter),
                Text(time, style: tvText(8, TvColors.dim)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
