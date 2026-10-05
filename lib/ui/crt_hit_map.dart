import 'package:codedbykay_text_tv/model/crt_geometry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Sends a touch to the child as if the child were drawn with the CRT bulge:
/// where the glass shows a link, a tap on it reaches the link, however far the
/// bulge has moved it from where it is laid out. Nothing is drawn or laid out
/// differently; only where touches land. A touch on the dark beyond the glass
/// reaches nothing.
///
/// The touch's position is mapped once, when it lands, and a drag then moves
/// by the same amount, which is as exact as the glass is gentle.
class CrtHitMap extends SingleChildRenderObjectWidget {
  const CrtHitMap({super.key, required this.curve, super.child});

  /// The bulge, as in the shader; 0 leaves touches alone.
  final double curve;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCrtHitMap(curve);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderCrtHitMap).curve = curve;
  }
}

class _RenderCrtHitMap extends RenderProxyBox {
  _RenderCrtHitMap(this.curve);

  double curve;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;
    if (child == null) return false;
    final ({double x, double y})? source = crtSourcePoint(
      position.dx,
      position.dy,
      size.width,
      size.height,
      curve,
    );
    if (source == null) return false;
    final Offset shift = Offset(source.x - position.dx, source.y - position.dy);
    return result.addWithRawTransform(
      transform: Matrix4.translationValues(shift.dx, shift.dy, 0),
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) =>
          child.hitTest(result, position: position),
    );
  }
}
