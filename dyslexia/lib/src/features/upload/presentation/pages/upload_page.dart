import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../routes/app_route_path.dart';
import '../bloc/upload/upload_bloc.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // === BACKGROUND 2 LAPIS UNGU (Disamakan dengan Pre-Screening) ===
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 140, // Tinggi tetap agar konsisten
              decoration: const BoxDecoration(
                color: Color(0xFFE0D5F7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120, // Tinggi tetap agar konsisten
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE0D5F7), Color(0xFFB596E5)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),

          // === KONTEN UTAMA ===
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: BlocConsumer<UploadBloc, UploadState>(
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
                      showAdaptiveFeedback(context, state.message);
                    }
                  },
                  builder: (context, state) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: state is UploadLoadingState
                                ? const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFB596E5),
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Extracting text from file...',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0D5F7).withOpacity(0.4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.upload_file_rounded,
                                          size: 48,
                                          color: Color(0xFFB596E5),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Pick a file to extract text',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Image and document files are supported.',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      FilledButton.icon(
                                        onPressed: () => context
                                            .read<UploadBloc>()
                                            .add(PickAndExtractEvent()),
                                        icon: const Icon(Icons.folder_open_rounded),
                                        label: const Text('Choose File'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFFB596E5),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              fixedSize: const Size(40, 40),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Upload File',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}