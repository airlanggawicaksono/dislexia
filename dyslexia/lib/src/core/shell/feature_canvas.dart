import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../configs/injector/injector_conf.dart';
import '../../core/constants/sample_text.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/display_settings/presentation/theme/display_colors.dart';
import '../../features/upload/data/datasources/pdf_extractor_service.dart';

/// Feature canvas: a vertical column of feature buttons including the
/// Reader. Migrated from the previous [DyslexiaTopbar] so that the desktop
/// shell can adopt a 3-column layout. Acts as the source of input for
/// the reader.
class FeatureCanvas extends StatefulWidget {
  final void Function(String text, String? source) onTextExtracted;
  final void Function(int current, int total)? onPdfProgress;
  final void Function(String message) onFeedback;
  const FeatureCanvas({
    super.key,
    required this.onTextExtracted,
    this.onPdfProgress,
    required this.onFeedback,
  });

  @override
  State<FeatureCanvas> createState() => FeatureCanvasState();
}

class FeatureCanvasState extends State<FeatureCanvas> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    widget.onTextExtracted(text, 'Manual Input');
  }

  Future<void> _onUploadPdf() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Required for web to get bytes
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) widget.onFeedback('Could not read file data');
        return;
      }

      widget.onPdfProgress?.call(0, 1); // Show indeterminate progress

      final text = await getIt<PdfExtractorService>().extractText(
        bytes,
        onProgress: widget.onPdfProgress,
      );

      if (text.trim().isEmpty) {
        if (mounted) {
          widget.onFeedback('PDF appears to be empty or contains only images');
        }
        return;
      }
      widget.onTextExtracted(text, file.name);
    } catch (e) {
      if (mounted) widget.onFeedback('Failed to read PDF: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onPdfProgress?.call(1, 1); // Hide progress
      }
    }
  }

  Future<void> _onPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      widget.onFeedback('Nothing found in clipboard');
      return;
    }
    _controller.text = text;
    widget.onTextExtracted(text, 'Clipboard');
  }

  void _onSample() {
    _controller.text = '';
    widget.onTextExtracted(kDyslexiaSampleText, 'Sample');
  }

  void _onReader() {
    // Reader button: open the dyslexia sample as a quick demo.
    _controller.text = '';
    widget.onTextExtracted(kDyslexiaSampleText, 'Sample');
  }

  void triggerUploadPdf() => _onUploadPdf();

  void triggerSample() => _onSample();

  void setText(String text) => _controller.text = text;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final bg = bgColor(state.settings.colorTheme);
        final fg = fgColor(state.settings.colorTheme);
        final tileColor = fg.withValues(alpha: 0.08);
        final iconBgColor = fg.withValues(alpha: 0.12);

        return Container(
          width: 220,
          decoration: BoxDecoration(
            color: bg,
            border: Border(right: BorderSide(color: fg.withValues(alpha: 0.08))),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                Row(
                  children: [
                    const Icon(Icons.accessibility_new,
                        color: Color(0xFF3D5A99), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Features',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: fg),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FeatureTile(
                  tileColor: tileColor,
                  iconBgColor: iconBgColor,
                  fgColor: fg,
                  icon: _isCupertino
                      ? CupertinoIcons.book
                      : Icons.menu_book_rounded,
                  label: 'Reader',
                  onTap: _onReader,
                ),
                const SizedBox(height: 8),
                _FeatureTile(
                  tileColor: tileColor,
                  iconBgColor: iconBgColor,
                  fgColor: fg,
                  icon: _isCupertino
                      ? CupertinoIcons.cloud_upload
                      : Icons.upload_file_rounded,
                  label: 'Upload PDF',
                  onTap: _isLoading ? null : _onUploadPdf,
                ),
                const SizedBox(height: 8),
                _FeatureTile(
                  tileColor: tileColor,
                  iconBgColor: iconBgColor,
                  fgColor: fg,
                  icon: _isCupertino
                      ? CupertinoIcons.doc_on_clipboard
                      : Icons.content_paste_rounded,
                  label: 'Paste',
                  onTap: _isLoading ? null : _onPaste,
                ),
                const SizedBox(height: 8),
                _FeatureTile(
                  tileColor: tileColor,
                  iconBgColor: iconBgColor,
                  fgColor: fg,
                  icon: _isCupertino
                      ? CupertinoIcons.book
                      : Icons.menu_book_rounded,
                  label: 'Sample',
                  onTap: _isLoading ? null : _onSample,
                ),
                const SizedBox(height: 16),
                _Label(title: 'TYPE OR PASTE', color: fg.withValues(alpha: 0.5)),
                const SizedBox(height: 6),
                _buildInput(fg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput(Color fg) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Masukkan teks di sini...',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3D5A99), width: 1.5),
          ),
        ),
        style: const TextStyle(fontSize: 14),
        onChanged: _onTextChanged,
      ),
    );
  }
}

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class _Label extends StatelessWidget {
  final String title;
  final Color color;
  const _Label({required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.8)),
      );
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color tileColor;
  final Color iconBgColor;
  final Color fgColor;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tileColor,
    required this.iconBgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final effectiveTile = disabled ? tileColor.withValues(alpha: 0.4) : tileColor;
    final effectiveFg = disabled ? fgColor.withValues(alpha: 0.4) : fgColor;

    if (_isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: effectiveTile,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: effectiveFg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: effectiveFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: effectiveTile,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: effectiveFg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: effectiveFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
