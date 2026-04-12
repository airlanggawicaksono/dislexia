import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scalable_ocr/flutter_scalable_ocr.dart';

import '../../../../core/themes/feature_neutral_theme.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../bloc/lens/lens_bloc.dart';
import '../widgets/live_text_panel.dart';

class LensPage extends StatefulWidget {
  const LensPage({super.key});

  @override
  State<LensPage> createState() => _LensPageState();
}

class _LensPageState extends State<LensPage> {
  List<dynamic> _rawElements = const [];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, displayState) {
        final s = displayState.settings;
        return Scaffold(
          backgroundColor: FeatureNeutralTheme.background,
          appBar: AppBar(
            backgroundColor: FeatureNeutralTheme.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme:
                const IconThemeData(color: FeatureNeutralTheme.textPrimary),
            title: const Text(
              'Lens',
              style: TextStyle(
                color: FeatureNeutralTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final cameraHeight = constraints.maxHeight * 2 / 3;
              final panelHeight = constraints.maxHeight * 1 / 3;
              return Column(
                children: [
                  SizedBox(
                    height: cameraHeight,
                    child: ClipRect(child: ScalableOCR(
                      paintboxCustom: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4.0
                        ..color = const Color(0xCC4C658A),
                      boxHeight: cameraHeight * 0.82,
                      boxLeftOff: 12.0,
                      boxRightOff: 12.0,
                      boxTopOff: 8.0,
                      boxBottomOff: 8.0,
                      getRawData: (value) {
                        if (value is List) {
                          _rawElements = List<dynamic>.from(value);
                        }
                      },
                      getScannedText: (value) {
                        context.read<LensBloc>().add(
                              AnalyzeFrameEvent(
                                value.toString(),
                                rawElements: _rawElements,
                              ),
                            );
                      },
                    )),
                  ),
                  BlocBuilder<LensBloc, LensState>(
                    buildWhen: (_, current) => current is LensLiveState,
                    builder: (context, lensState) {
                      final frame =
                          lensState is LensLiveState ? lensState.frame : null;
                      return SizedBox(
                        height: panelHeight,
                        child: LiveTextPanel(
                          text: frame?.text ?? '',
                          settings: s,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
