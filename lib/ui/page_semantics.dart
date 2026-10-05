import 'package:codedbykay_text_tv/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

/// Gives the page on show a node of its own for a screen reader: `Page 377,
/// part 1 of 2`, announced when it changes (a new page, or another part), with
/// the rows and links inside it as separate nodes after it.
class PageSemantics extends StatelessWidget {
  const PageSemantics({
    super.key,
    required this.page,
    required this.part,
    required this.parts,
    required this.child,
  });

  final int page;

  /// Which part is on show, from 0.
  final int part;
  final int parts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      textDirection: Directionality.of(context),
      label: context.l10n.pageDescription(page, part, parts),
      child: child,
    );
  }
}
