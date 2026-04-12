import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/feature_neutral_theme.dart';
import '../../../../routes/app_route_path.dart';
import '../bloc/upload/upload_bloc.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

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
          'Upload File',
          style: TextStyle(
            color: FeatureNeutralTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocConsumer<UploadBloc, UploadState>(
        listener: (context, state) {
          if (state is UploadSuccessState) {
            context.pushNamed(
              AppRoute.textPad.name,
              extra: {
                'text': state.document.text ?? '',
                'sourceName': state.document.sourceName,
              },
            );
          } else if (state is UploadFailureState) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  decoration: FeatureNeutralTheme.panelDecoration(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  child: state is UploadLoadingState
                      ? const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: FeatureNeutralTheme.accent,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Extracting text from file...',
                              style: TextStyle(
                                color: FeatureNeutralTheme.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.upload_file_rounded,
                              size: 72,
                              color: FeatureNeutralTheme.accent,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Pick a file to extract text',
                              style: TextStyle(
                                color: FeatureNeutralTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Image and document files are supported.',
                              style: TextStyle(
                                color: FeatureNeutralTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: FeatureNeutralTheme.primaryButtonStyle(),
                              icon: const Icon(Icons.folder_open_rounded),
                              label: const Text('Choose File'),
                              onPressed: () => context
                                  .read<UploadBloc>()
                                  .add(PickAndExtractEvent()),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
