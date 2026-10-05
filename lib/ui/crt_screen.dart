import 'package:codedbykay_text_tv/model/crt_settings.dart';
import 'package:codedbykay_text_tv/ui/crt_hit_map.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

/// Draws [child] as if on a CRT tube, as [settings] say: bulging glass,
/// scanlines, a little colour fringing and a vignette. The child is captured
/// as a picture and redrawn through `shaders/crt.frag`; until the shader has
/// loaded it is shown as it is.
///
/// Taps are mapped through the same bulge (see [CrtHitMap]), so a tap on what
/// the glass shows reaches it, at any curvature.
class CrtScreen extends StatelessWidget {
  const CrtScreen({super.key, required this.child, required this.settings});

  final Widget child;
  final CrtSettings settings;

  static const String shaderAsset = 'shaders/crt.frag';

  @override
  Widget build(BuildContext context) {
    return ShaderBuilder(
      assetKey: shaderAsset,
      child: child,
      // The touch map is inside the builder, so it only bends touches once the
      // shader is there to bend what is drawn.
      (BuildContext context, shader, Widget? child) => CrtHitMap(
        curve: settings.enabled ? settings.curve : 0,
        child: AnimatedSampler(
          (image, size, canvas) {
            shader
              ..setFloat(0, size.width)
              ..setFloat(1, size.height)
              ..setFloat(2, settings.curve)
              ..setFloat(3, settings.scanDepth)
              ..setFloat(4, settings.scanPeriod)
              ..setImageSampler(0, image);
            canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
          },
          enabled: settings.enabled,
          child: child!,
        ),
      ),
    );
  }
}
