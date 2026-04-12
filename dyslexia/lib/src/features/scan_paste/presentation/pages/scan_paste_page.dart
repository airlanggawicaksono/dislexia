import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/themes/feature_neutral_theme.dart';
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
      // user cancelled — go back
      context.pop();
      return;
    }

    context.read<ScanBloc>().add(StartScanEvent(photo.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FeatureNeutralTheme.background,
      appBar: AppBar(
        backgroundColor: FeatureNeutralTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: FeatureNeutralTheme.textPrimary),
        title: const Text(
          'Scan with Camera',
          style: TextStyle(
            color: FeatureNeutralTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            context.pop();
          }
        },
        child: BlocBuilder<ScanBloc, ScanState>(
          builder: (context, state) {
            if (state is ScanLoadingState) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  decoration: FeatureNeutralTheme.panelDecoration(),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          color: FeatureNeutralTheme.accent),
                      SizedBox(height: 14),
                      Text(
                        'Reading text...',
                        style: TextStyle(
                            color: FeatureNeutralTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }
            // Initial state — camera is opening, show a neutral loader
            return const Center(
              child: CircularProgressIndicator(
                  color: FeatureNeutralTheme.accent),
            );
          },
        ),
      ),
    );
  }
}
