import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/theme_settings_controller.dart';

class LoadingStyleSettingsPage extends StatelessWidget {
  const LoadingStyleSettingsPage({super.key});

  ThemeSettingsController get _theme => Get.find<ThemeSettingsController>();

  static const List<Map<String, String>> _styles = [
    {'key': 'default', 'name': 'Default Ring'},
    {'key': 'ballPulse', 'name': 'Ball Pulse'},
    {'key': 'ballGridPulse', 'name': 'Ball Grid Pulse'},
    {'key': 'ballClipRotate', 'name': 'Ball Clip Rotate'},
    {'key': 'squareSpin', 'name': 'Square Spin'},
    {'key': 'ballClipRotatePulse', 'name': 'Ball Clip Rotate Pulse'},
    {'key': 'ballClipRotateMultiple', 'name': 'Ball Clip Rotate Multiple'},
    {'key': 'ballPulseRise', 'name': 'Ball Pulse Rise'},
    {'key': 'ballRotate', 'name': 'Ball Rotate'},
    {'key': 'cubeTransition', 'name': 'Cube Transition'},
    {'key': 'ballZigZag', 'name': 'Ball ZigZag'},
    {'key': 'ballZigZagDeflect', 'name': 'Ball ZigZag Deflect'},
    {'key': 'ballTrianglePath', 'name': 'Ball Triangle Path'},
    {'key': 'ballScale', 'name': 'Ball Scale'},
    {'key': 'lineScale', 'name': 'Line Scale'},
    {'key': 'lineScaleParty', 'name': 'Line Scale Party'},
    {'key': 'ballScaleMultiple', 'name': 'Ball Scale Multiple'},
    {'key': 'ballPulseSync', 'name': 'Ball Pulse Sync'},
    {'key': 'ballBeat', 'name': 'Ball Beat'},
    {'key': 'lineScalePulseOut', 'name': 'Line Scale Pulse Out'},
    {'key': 'lineScalePulseOutRapid', 'name': 'Line Scale Pulse Out Rapid'},
    {'key': 'ballScaleRipple', 'name': 'Ball Scale Ripple'},
    {'key': 'ballScaleRippleMultiple', 'name': 'Ball Scale Ripple Multiple'},
    {'key': 'ballSpinFadeLoader', 'name': 'Ball Spin Fade Loader'},
    {'key': 'lineSpinFadeLoader', 'name': 'Line Spin Fade Loader'},
    {'key': 'triangleSkewSpin', 'name': 'Triangle Skew Spin'},
    {'key': 'pacman', 'name': 'Pacman'},
    {'key': 'ballGridBeat', 'name': 'Ball Grid Beat'},
    {'key': 'semiCircleSpin', 'name': 'Semi Circle Spin'},
    {'key': 'ballRotateChase', 'name': 'Ball Rotate Chase'},
    {'key': 'orbit', 'name': 'Orbit'},
    {'key': 'audioEqualizer', 'name': 'Audio Equalizer'},
    {'key': 'circleStrokeSpin', 'name': 'Circle Stroke Spin'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(i18n("change_loading_style"))),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _styles.length,
        itemBuilder: (context, index) {
          final style = _styles[index];
          final isSelected = _theme.loadingStyle.v == style['key'];

          return GestureDetector(
            onTap: () {
              _theme.loadingStyle.v = style['key']!;
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: LoadingIndicator(
                      indicatorType: _getIndicatorType(style['key']!),
                      colors: [Theme.of(context).colorScheme.primary],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    style['name']!,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Indicator _getIndicatorType(String key) {
    switch (key) {
      case 'ballPulse':
        return Indicator.ballPulse;
      case 'ballGridPulse':
        return Indicator.ballGridPulse;
      case 'ballClipRotate':
        return Indicator.ballClipRotate;
      case 'squareSpin':
        return Indicator.squareSpin;
      case 'ballClipRotatePulse':
        return Indicator.ballClipRotatePulse;
      case 'ballClipRotateMultiple':
        return Indicator.ballClipRotateMultiple;
      case 'ballPulseRise':
        return Indicator.ballPulseRise;
      case 'ballRotate':
        return Indicator.ballRotate;
      case 'cubeTransition':
        return Indicator.cubeTransition;
      case 'ballZigZag':
        return Indicator.ballZigZag;
      case 'ballZigZagDeflect':
        return Indicator.ballZigZagDeflect;
      case 'ballTrianglePath':
        return Indicator.ballTrianglePath;
      case 'ballScale':
        return Indicator.ballScale;
      case 'lineScale':
        return Indicator.lineScale;
      case 'lineScaleParty':
        return Indicator.lineScaleParty;
      case 'ballScaleMultiple':
        return Indicator.ballScaleMultiple;
      case 'ballPulseSync':
        return Indicator.ballPulseSync;
      case 'ballBeat':
        return Indicator.ballBeat;
      case 'lineScalePulseOut':
        return Indicator.lineScalePulseOut;
      case 'lineScalePulseOutRapid':
        return Indicator.lineScalePulseOutRapid;
      case 'ballScaleRipple':
        return Indicator.ballScaleRipple;
      case 'ballScaleRippleMultiple':
        return Indicator.ballScaleRippleMultiple;
      case 'ballSpinFadeLoader':
        return Indicator.ballSpinFadeLoader;
      case 'lineSpinFadeLoader':
        return Indicator.lineSpinFadeLoader;
      case 'triangleSkewSpin':
        return Indicator.triangleSkewSpin;
      case 'pacman':
        return Indicator.pacman;
      case 'ballGridBeat':
        return Indicator.ballGridBeat;
      case 'semiCircleSpin':
        return Indicator.semiCircleSpin;
      case 'ballRotateChase':
        return Indicator.ballRotateChase;
      case 'orbit':
        return Indicator.orbit;
      case 'audioEqualizer':
        return Indicator.audioEqualizer;
      case 'circleStrokeSpin':
        return Indicator.circleStrokeSpin;
      default:
        return Indicator.circleStrokeSpin;
    }
  }
}
