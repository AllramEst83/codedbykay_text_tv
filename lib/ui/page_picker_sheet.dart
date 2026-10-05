import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:codedbykay_text_tv/model/saved_pages.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// Opens a list of pages to choose one from: the pages the reader keeps (the
/// favourites) and has read lately, with [selected] first and marked. The sheet
/// closes itself when one is chosen and [onPick] is told which.
Future<void> showPagePicker(
  BuildContext context, {
  required String title,
  required int selected,
  required List<Favourite> favourites,
  required List<int> recents,
  required ValueChanged<int> onPick,
}) {
  final List<int> pages = <int>[
    selected,
    for (final Favourite f in favourites)
      if (f.page != selected) f.page,
    for (final int r in recents)
      if (r != selected && !favourites.any((Favourite f) => f.page == r)) r,
  ];
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: tvText(12, TvColors.white)),
            const SizedBox(height: TvMetrics.margin),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final int page in pages)
                    _PickRow(
                      page: page,
                      label: sheet.l10n.chipLabel(
                        favourites.firstWhere(
                          (Favourite f) => f.page == page,
                          orElse: () => Favourite(page),
                        ),
                      ),
                      selected: page == selected,
                      onTap: () {
                        Navigator.of(sheet).pop();
                        onPick(page);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: TvMetrics.gutter),
            Text(sheet.l10n.pickerHint, style: tvText(8, TvColors.dim)),
          ],
        ),
      ),
    ),
  );
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.page,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.pageLabel(page),
      excludeSemantics: true,
      child: InkWell(
        key: textTvPickKey(page),
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
            style: tvText(12, selected ? TvColors.highlight : TvColors.white),
          ),
        ),
      ),
    );
  }
}
