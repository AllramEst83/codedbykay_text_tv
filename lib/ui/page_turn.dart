import 'package:flutter/material.dart';

/// Brings a new page in with a short slide and fade, from the side it was
/// turned to: a later page from the right, an earlier one from the left. Only
/// the new page animates, and the old one is already gone, so there is never
/// more than one page in the tree. Give it a new key for each page.
///
/// [direction] is 1 for a later page, -1 for an earlier one and 0 for none
/// (the first page, or the same page read again); the phone's own "remove
/// animations" setting turns it off too.
class PageTurn extends StatefulWidget {
  const PageTurn({super.key, required this.direction, required this.child});

  final int direction;
  final Widget child;

  /// How long a turn takes: enough to see, not enough to wait for.
  static const Duration duration = Duration(milliseconds: 180);

  @override
  State<PageTurn> createState() => _PageTurnState();
}

class _PageTurnState extends State<PageTurn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PageTurn.duration,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final bool still =
        widget.direction == 0 || MediaQuery.disableAnimationsOf(context);
    if (still) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double t = _curve.value;
        return Opacity(
          opacity: t,
          child: FractionalTranslation(
            translation: Offset(0.1 * widget.direction * (1 - t), 0),
            child: child,
          ),
        );
      },
    );
  }
}
