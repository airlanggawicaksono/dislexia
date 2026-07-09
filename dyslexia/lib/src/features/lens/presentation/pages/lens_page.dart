import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/feature_neutral_theme.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../routes/app_route_path.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../bloc/lens/lens_bloc.dart';
import '../widgets/line_box_painter.dart';
import '../widgets/live_text_panel.dart';

class LensPage extends StatefulWidget {
  const LensPage({super.key});

  @override
  State<LensPage> createState() => _LensPageState();
}

class _LensPageState extends State<LensPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<LensBloc>().add(StartLensEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Bloc is closed by its BlocProvider, which also stops the camera.
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final bloc = context.read<LensBloc>();
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      bloc.add(StopLensEvent());
    } else if (state == AppLifecycleState.resumed) {
      bloc.add(StartLensEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, displayState) {
        final settings = displayState.settings;
        return AdaptiveScaffold(
          backgroundColor: FeatureNeutralTheme.background,
          title: 'Lens',
          titleColor: FeatureNeutralTheme.textPrimary,
          body: BlocConsumer<LensBloc, LensState>(
            listenWhen: (_, curr) => curr is LensSuccessState,
            listener: (context, state) {
              if (state is LensSuccessState) {
                context.push(
                  AppRoute.textPad.path,
                  extra: {
                    'text': state.document.text ?? '',
                    'sourceName': state.document.sourceName,
                  },
                );
              }
            },
            builder: (context, state) {
              if (state is LensFailureState) {
                return _ErrorView(
                  message: state.message,
                  onRetry: () => context.read<LensBloc>().add(StartLensEvent()),
                );
              }
              if (state is LensLiveState) {
                return _LiveView(frame: state, settings: settings);
              }
              // Initial / starting.
              return const Center(child: CircularProgressIndicator());
            },
          ),
        );
      },
    );
  }
}

class _LiveView extends StatelessWidget {
  final LensLiveState frame;
  final dynamic settings;

  const _LiveView({required this.frame, required this.settings});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<LensBloc>().previewController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Full-bleed camera with a floating rounded text card over it. Tapping
    // the card captures the current text into the reader.
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CoverCameraPreview(controller: controller),
          Positioned.fill(
            child: CustomPaint(painter: LineBoxPainter(frame.frame)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => context.read<LensBloc>().add(CaptureTextEvent()),
              child: LiveTextPanel(
                text: frame.frame.fullText,
                settings: settings,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fills the available box with the camera feed (BoxFit.cover) so the
/// preview isn't letterboxed — keeps the box-overlay maths simple.
class _CoverCameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CoverCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? constraints.maxWidth,
            height: controller.value.previewSize?.width ?? constraints.maxHeight,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
