import 'package:codedbykay_text_tv/messages.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// Opens the pages read last over the page, the latest first, for a tap to
/// open one. [recents] should leave out the page on show (it is not a place to
/// go back to); [favourites] only supply names for the ones that have them.
/// The sheet closes itself when a page is chosen or the list is cleared.
Future<void> showRecentPages(
  BuildContext context, {
  required List<int> recents,
  required List<Favourite> favourites,
  required ValueChanged<int> onOpen,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TvColors.black,
    barrierColor: Colors.black38,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(),
    builder: (BuildContext sheet) => SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: TvColors.border, width: TvMetrics.border),
          ),
        ),
        padding: const EdgeInsets.all(TvMetrics.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(Messages.recentsTitle, style: tvText(12, TvColors.white)),
            const SizedBox(height: TvMetrics.margin),
            if (recents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TvMetrics.margin),
                child: Text(
                  Messages.recentsEmpty,
                  key: textTvRecentsEmptyKey,
                  style: tvText(10, TvColors.dim),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final int page in recents)
                      _RecentRow(
                        page: page,
                        label: favourites
                            .firstWhere(
                              (Favourite f) => f.page == page,
                              orElse: () => Favourite(page),
                            )
                            .label,
                        onTap: () {
                          Navigator.of(sheet).pop();
                          onOpen(page);
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: TvMetrics.margin),
            TvButton(
              key: textTvRecentsClearKey,
              label: Messages.clearRecents,
              onTap: recents.isEmpty
                  ? null
                  : () {
                      Navigator.of(sheet).pop();
                      onClear();
                    },
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.page,
    required this.label,
    required this.onTap,
  });

  final int page;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: Messages.pageLabel(page),
      excludeSemantics: true,
      child: InkWell(
        key: textTvRecentKey(page),
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
          child: Text(label, style: tvText(12, TvColors.white)),
        ),
      ),
    );
  }
}
