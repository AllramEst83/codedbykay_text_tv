import 'package:codedbykay_text_tv/ui/text_tv_controls.dart';
import 'package:codedbykay_text_tv/ui/theme.dart';
import 'package:flutter/material.dart';

/// A labelled on/off switch in the viewer's black and yellow. Used by the
/// settings page and the reader's options.
class TvSwitchRow extends StatelessWidget {
  const TvSwitchRow({
    super.key,
    required this.switchKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  /// Key of the [Switch] itself, for finding it.
  final Key switchKey;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      toggled: value,
      child: Row(
        children: <Widget>[
          Expanded(
            child: ExcludeSemantics(
              child: Text(label, style: tvText(12, TvColors.white)),
            ),
          ),
          Switch(
            key: switchKey,
            value: value,
            onChanged: onChanged,
            activeThumbColor: TvColors.black,
            activeTrackColor: TvColors.highlight,
            inactiveThumbColor: TvColors.white,
            inactiveTrackColor: TvColors.black,
            trackOutlineColor: WidgetStatePropertyAll<Color>(
              value ? TvColors.highlight : TvColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled slider with its value written beside the label. [divisions]
/// makes it step; a slider can only be moved between [min] and [max], so it is
/// also what keeps a setting inside its range.
class TvSliderRow extends StatelessWidget {
  const TvSliderRow({
    super.key,
    required this.sliderKey,
    required this.label,
    required this.value,
    required this.text,
    required this.onChanged,
    this.min = 0,
    required this.max,
    this.divisions = 20,
  });

  /// Key of the [Slider] itself, for finding it.
  final Key sliderKey;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;

  /// The value as shown next to the label.
  final String text;

  /// Null greys the slider, for when what it sets is off.
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final Color colour = onChanged == null ? TvColors.dim : TvColors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: tvText(10, colour))),
            Text(text, style: tvText(10, colour)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: TvColors.highlight,
            inactiveTrackColor: TvColors.border,
            thumbColor: TvColors.highlight,
            disabledActiveTrackColor: TvColors.dim,
            disabledInactiveTrackColor: TvColors.border,
            disabledThumbColor: TvColors.dim,
            overlayColor: TvColors.highlight.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            key: sliderKey,
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            semanticFormatterCallback: (double v) => '$label $text',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
