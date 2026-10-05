import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:codedbykay_text_tv/model/text_tv_page.dart';
import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/text_tv_keys.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// The way down to the page on show, from the start page: `HOME > SPORT >
/// RESULTS > 377`, each step a tap back up the tree (from 377 back to the
/// results on 330, to sport on 300, or home). The last step is the page itself,
/// in yellow, and not a button. Scrolls sideways when it is longer than the
/// screen, showing its end.
class TvBreadcrumbs extends StatefulWidget {
  const TvBreadcrumbs({
    super.key,
    required this.crumbs,
    required this.current,
    required this.onOpen,
  });

  final List<Crumb> crumbs;

  /// The page on show: the crumb for it is the last one and not tappable.
  final int current;
  final ValueChanged<int> onOpen;

  @override
  State<TvBreadcrumbs> createState() => _TvBreadcrumbsState();
}

class _TvBreadcrumbsState extends State<TvBreadcrumbs> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _showEnd();
  }

  @override
  void didUpdateWidget(TvBreadcrumbs old) {
    super.didUpdateWidget(old);
    _showEnd();
  }

  /// A longer path than the screen: show where it ends, which is the page.
  void _showEnd() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  /// The site calls the first step `Hem`; the app says it in its own language.
  String _label(BuildContext context, Crumb crumb, int index) =>
      (index == 0 && crumb.name.toLowerCase() == 'hem'
              ? context.l10n.crumbHome
              : crumb.name)
          .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final List<Crumb> crumbs = widget.crumbs;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: context.l10n.crumbsLabel,
      child: SizedBox(
        key: textTvBreadcrumbsKey,
        height: 40,
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: TvMetrics.gutter),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < crumbs.length; i++) ...<Widget>[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('>', style: tvText(8, TvColors.dim)),
                  ),
                _Crumb(
                  key: textTvCrumbKey(crumbs[i].page),
                  label: _label(context, crumbs[i], i),
                  page: crumbs[i].page,
                  isCurrent:
                      crumbs[i].page == widget.current &&
                      i == crumbs.length - 1,
                  onTap: () => widget.onOpen(crumbs[i].page),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    super.key,
    required this.label,
    required this.page,
    required this.isCurrent,
    required this.onTap,
  });

  final String label;
  final int page;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget text = Center(
      child: Text(
        label,
        style: tvText(9, isCurrent ? TvColors.highlight : TvColors.white),
      ),
    );
    if (isCurrent) {
      return Semantics(
        label: '$label. ${context.l10n.pageLabel(page)}',
        selected: true,
        excludeSemantics: true,
        child: text,
      );
    }
    return Semantics(
      button: true,
      label: '$label. ${context.l10n.pageLabel(page)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 32),
          child: text,
        ),
      ),
    );
  }
}
