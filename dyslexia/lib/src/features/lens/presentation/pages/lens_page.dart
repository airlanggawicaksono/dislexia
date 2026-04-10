import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../bloc/lens/lens_bloc.dart';
import '../widgets/live_text_panel.dart';
import '../widgets/text_box_painter.dart';

class LensPage extends StatelessWidget {
  const LensPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, displayState) {
        final s = displayState.settings;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Lens',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: CameraAwesomeBuilder.previewOnly(
            onImageForAnalysis: (img) async {
              context.read<LensBloc>().add(AnalyzeFrameEvent(img));
            },
            imageAnalysisConfig: AnalysisConfig(
              androidOptions: const AndroidAnalysisOptions.nv21(width: 720),
              autoStart: true,
              maxFramesPerSecond: 15,
            ),
            builder: (CameraState camState, AnalysisPreview preview) {
              return BlocBuilder<LensBloc, LensState>(
                buildWhen: (_, current) => current is LensLiveState,
                builder: (context, lensState) {
                  final frame =
                      lensState is LensLiveState ? lensState.frame : null;
                  return Stack(
                    children: [
                      if (frame != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: TextBoxPainter(frame: frame),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LiveTextPanel(
                          text: frame?.text ?? '',
                          settings: s,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
