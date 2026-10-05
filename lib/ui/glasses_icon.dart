import 'package:flutter/widgets.dart';

/// A pair of reading glasses: two round lenses, a bridge and a short temple
/// at each side. Drawn rather than taken from an icon font, which has none.
class GlassesIcon extends StatelessWidget {
  const GlassesIcon({super.key, required this.colour, this.size = 32});

  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _GlassesPainter(colour));
}

class _GlassesPainter extends CustomPainter {
  const _GlassesPainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint stroke = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    final double radius = w * 0.21;
    final double y = h * 0.52;
    canvas
      ..drawCircle(Offset(w * 0.26, y), radius, stroke)
      ..drawCircle(Offset(w * 0.74, y), radius, stroke)
      // The bridge between the lenses, and a temple going back from each.
      ..drawArc(
        Rect.fromCenter(
          center: Offset(w * 0.5, y - h * 0.02),
          width: w * 0.12,
          height: h * 0.1,
        ),
        3.14159,
        3.14159,
        false,
        stroke,
      )
      ..drawLine(Offset(w * 0.07, y), Offset(w * 0.02, h * 0.38), stroke)
      ..drawLine(Offset(w * 0.93, y), Offset(w * 0.98, h * 0.38), stroke);
  }

  @override
  bool shouldRepaint(_GlassesPainter old) => old.colour != colour;
}
