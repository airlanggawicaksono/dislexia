import 'dart:math' as math;

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/utils/font_utils.dart';
import '../../../../core/utils/mlkit_utils.dart';
import '../../../display_settings/domain/entities/display_settings_entity.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';

class LensPage extends StatefulWidget {
  const LensPage({super.key});

  @override
  State<LensPage> createState() => _LensPageState();
}

class _LensPageState extends State<LensPage> {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  String _liveText = '';
  List<TextBlock> _blocks = [];
  Size _imageSize = Size.zero;
  bool _isRotated = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _analyzeImage(AnalysisImage img) async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final inputImage = img.toInputImage();
      final result = await _recognizer.processImage(inputImage);
      final text = result.text.trim();
      if (mounted) {
        setState(() {
          _liveText = text;
          _blocks = result.blocks;
          _imageSize = img.size;
          // rotation90 / rotation270 means sensor is landscape → coords are flipped
          _isRotated = img.rotation.name.contains('90') ||
              img.rotation.name.contains('270');
        });
      }
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final s = state.settings;
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
            onImageForAnalysis: _analyzeImage,
            imageAnalysisConfig: AnalysisConfig(
              androidOptions: const AndroidAnalysisOptions.nv21(width: 720),
              autoStart: true,
              maxFramesPerSecond: 15,
            ),
            builder: (CameraState camState, AnalysisPreview preview) {
              return Stack(
                children: [
                  // ── bounding box overlay ──────────────────────────────────
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TextBoxPainter(
                        blocks: _blocks,
                        imageSize: _imageSize,
                        isRotated: _isRotated,
                      ),
                    ),
                  ),
                  // ── live text panel ───────────────────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _LiveTextPanel(text: _liveText, settings: s),
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

// ── Bounding box painter ──────────────────────────────────────────────────────

class _TextBoxPainter extends CustomPainter {
  final List<TextBlock> blocks;
  final Size imageSize;
  final bool isRotated;

  _TextBoxPainter({
    required this.blocks,
    required this.imageSize,
    required this.isRotated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero || blocks.isEmpty) return;

    // Effective image dims after accounting for sensor rotation
    final double imgW = isRotated ? imageSize.height : imageSize.width;
    final double imgH = isRotated ? imageSize.width : imageSize.height;

    // CameraAwesome preview = BoxFit.cover:
    // scale so the image fully covers the screen, then center-crop the overflow
    final double scale = math.max(size.width / imgW, size.height / imgH);
    final double dx = (imgW * scale - size.width) / 2;
    final double dy = (imgH * scale - size.height) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF4FC3F7);

    for (final block in blocks) {
      if (block.lines.length >= 2) {
        // ── paragraph → one box around the whole block ───────────────────
        final box = block.boundingBox;
        if (box != null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              _transform(box, scale, dx, dy),
              const Radius.circular(4),
            ),
            paint,
          );
        }
      } else {
        // ── isolated phrase / word group → box per line ───────────────────
        for (final line in block.lines) {
          final box = line.boundingBox;
          if (box != null) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                _transform(box, scale, dx, dy),
                const Radius.circular(4),
              ),
              paint,
            );
          }
        }
      }
    }
  }

  Rect _transform(Rect r, double scale, double dx, double dy) => Rect.fromLTRB(
        r.left * scale - dx,
        r.top * scale - dy,
        r.right * scale - dx,
        r.bottom * scale - dy,
      );

  @override
  bool shouldRepaint(_TextBoxPainter old) =>
      old.blocks != blocks || old.imageSize != imageSize || old.isRotated != isRotated;
}

// ── Live text panel ───────────────────────────────────────────────────────────

class _LiveTextPanel extends StatelessWidget {
  final String text;
  final DisplaySettingsEntity settings;

  const _LiveTextPanel({required this.text, required this.settings});

  static const _themeColors = {
    AppColorTheme.white: (Color(0xFFFFFFFF), Color(0xFF1A1A1A)),
    AppColorTheme.cream: (Color(0xFFFFF8EE), Color(0xFF1A1A1A)),
    AppColorTheme.softYellow: (Color(0xFFFFFBCC), Color(0xFF1A1A1A)),
    AppColorTheme.mintGreen: (Color(0xFFE0F5E9), Color(0xFF1A1A1A)),
    AppColorTheme.lavender: (Color(0xFFEDE7F6), Color(0xFF1A1A1A)),
    AppColorTheme.skyBlue: (Color(0xFFE3F2FD), Color(0xFF1A1A1A)),
    AppColorTheme.peach: (Color(0xFFFFE8D6), Color(0xFF1A1A1A)),
    AppColorTheme.dark: (Color(0xFF1E1E1E), Color(0xFFE8E8E8)),
  };

  Color get _bg => _themeColors[settings.colorTheme]?.$1 ?? const Color(0xFFFFF8EE);
  Color get _fg => _themeColors[settings.colorTheme]?.$2 ?? const Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _fg.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: text.isEmpty
                ? Center(
                    child: Text(
                      'Point camera at text...',
                      style: TextStyle(color: _fg.withOpacity(0.4), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        text,
                        key: ValueKey(text),
                        style: applyDyslexiaFont(
                          font: settings.font,
                          baseStyle: TextStyle(
                            fontSize: settings.fontSize,
                            color: _fg,
                            height: settings.lineSpacing,
                            letterSpacing: settings.letterSpacing,
                            wordSpacing: settings.wordSpacing,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
