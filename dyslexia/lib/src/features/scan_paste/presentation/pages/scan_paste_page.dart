import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
                child: BlocListener<ScanBloc, ScanState>(
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
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
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
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFB596E5),
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Reading text...',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please wait while we extract the text.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      // State default (sebelum kamera terbuka atau saat menunggu)
                      return const Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: Color(0xFFB596E5),
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    },
                  ),
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
              'Scan with Camera',
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