import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/themes/feature_neutral_theme.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../routes/app_route_path.dart';
import '../bloc/scan/scan_bloc.dart';

class ScanPastePage extends StatefulWidget {
  const ScanPastePage({super.key});

  @override
  State<ScanPastePage> createState() => _ScanPastePageState();
}

class _ScanPastePageState extends State<ScanPastePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (!mounted) return;

    if (photo == null) {
      context.pop();
      return;
    }

    context.read<ScanBloc>().add(StartScanEvent(photo.path));
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      backgroundColor: FeatureNeutralTheme.background,
      title: 'Scan with Camera',
      titleColor: FeatureNeutralTheme.textPrimary,
      body: BlocListener<ScanBloc, ScanState>(
        listener: (context, state) {
          if (state is ScanSuccessState) {
            context.pushReplacementNamed(
              AppRoute.textPad.name,
              extra: {
                'text': state.document.text ?? '',
                'sourceName': state.document.sourceName,
              },
            );
          } else if (state is ScanFailureState) {
            showAdaptiveFeedback(context, state.message);
            context.pop();
          }
        },
        child: BlocBuilder<ScanBloc, ScanState>(
          builder: (context, state) {
            if (state is ScanLoadingState) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: FeatureNeutralTheme.panelDecoration(),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdaptiveProgressIndicator(
                          color: FeatureNeutralTheme.accent),
                      SizedBox(height: 14),
                      Text(
                        'Reading text...',
                        style:
                            TextStyle(color: FeatureNeutralTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(
              child:
                  AdaptiveProgressIndicator(color: FeatureNeutralTheme.accent),
            );
          },
        ),
      ),
    );
  }
}
