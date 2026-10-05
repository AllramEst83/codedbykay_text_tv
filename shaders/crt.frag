#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// The size of the area being drawn, in logical pixels.
uniform vec2 uSize;

// How far the glass bulges: 0 is flat. Scaled so the whole picture stays
// inside the screen at the middle of each edge; only the corners are cut.
// Touches are mapped the same way in lib/model/crt_geometry.dart: keep the
// two in step.
uniform float uCurve;

// How dark the scanline gaps are (0 = none) and how many logical pixels one
// line takes.
uniform float uScanDepth;
uniform float uScanPeriod;

// The widget under it, captured as a picture.
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec2 p = uv * 2.0 - 1.0;

  // Barrel distortion: look further out the further from the middle.
  vec2 q = p * (1.0 + uCurve * dot(p, p)) / (1.0 + uCurve);
  vec2 src = q * 0.5 + 0.5;

  // Beyond the glass: the dark edge of the tube.
  if (src.x < 0.0 || src.x > 1.0 || src.y < 0.0 || src.y > 1.0) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  // A hint of colour fringing, red and blue a hair apart.
  float fringe = 0.5 / uSize.x;
  vec3 col = vec3(
    texture(uTexture, src + vec2(fringe, 0.0)).r,
    texture(uTexture, src).g,
    texture(uTexture, src - vec2(fringe, 0.0)).b
  );

  // Scanlines.
  float line = 0.5 + 0.5 * sin(src.y * uSize.y * 6.2831853 / uScanPeriod);
  col *= 1.0 - uScanDepth + uScanDepth * line;

  // Brighter in the middle, softly dark toward the corners.
  col *= 1.08 - 0.3 * dot(p, p) * 0.5;

  // Soft edge where the picture meets the dark.
  float edge = min(min(src.x, 1.0 - src.x), min(src.y, 1.0 - src.y));
  col *= smoothstep(0.0, 0.02, edge);

  fragColor = vec4(col, 1.0);
}
