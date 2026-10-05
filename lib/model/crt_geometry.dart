/// Where on the flat page the CRT glass shows the thing at ([x], [y]) on the
/// screen, in an area of [width] by [height] with the bulge [curve].
///
/// The same mapping as `shaders/crt.frag` (keep the two in step): the shader
/// fills each screen pixel with the picture at this point, so this is also the
/// point a tap on that pixel should reach. Null where the screen is past the
/// glass (the dark corners), which shows nothing and so can be tapped for
/// nothing.
///
/// With [curve] 0 it is the identity. It is zero at the middle of the area and
/// at the middle of each edge, and largest about 58% of the way out.
({double x, double y})? crtSourcePoint(
  double x,
  double y,
  double width,
  double height,
  double curve,
) {
  if (width <= 0 || height <= 0) return null;
  final double px = x / width * 2 - 1;
  final double py = y / height * 2 - 1;
  final double scale = (1 + curve * (px * px + py * py)) / (1 + curve);
  final double sx = (px * scale * 0.5 + 0.5) * width;
  final double sy = (py * scale * 0.5 + 0.5) * height;
  if (sx < 0 || sx > width || sy < 0 || sy > height) return null;
  return (x: sx, y: sy);
}
