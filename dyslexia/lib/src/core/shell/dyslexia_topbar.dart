// DEPRECATED: superseded by FeatureCanvas in DesktopShell's 3-column layout.
// The top bar is no longer used by the desktop web shell; it is kept here for
// reference and possible reuse on other surfaces. See feature_canvas.dart for
// the active implementation.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../configs/injector/injector_conf.dart';
import '../../core/constants/sample_text.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/display_settings/presentation/theme/display_colors.dart';
import '../../features/upload/data/datasources/pdf_extractor_service.dart';

class DyslexiaTopbar extends StatefulWidget {
  final void Function(String text, String? source) onTextExtracted;
  final void Function(int current, int total)? onPdfProgress;
  const DyslexiaTopbar(
      {super.key, required this.onTextExtracted, this.onPdfProgress});
  @override
  State<DyslexiaTopbar> createState() => DyslexiaTopbarState();
}

class DyslexiaTopbarState extends State<DyslexiaTopbar> {
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
        if (mounted) _showFeedback('Could not read file data');
        return;
      }

      widget.onPdfProgress?.call(0, 1); // Show indeterminate progress

      final text = await getIt<PdfExtractorService>().extractText(
        bytes,
        onProgress: widget.onPdfProgress,
      );

      if (text.trim().isEmpty) {
        if (mounted) {
          _showFeedback('PDF appears to be empty or contains only images');
        }
        return;
      }
      widget.onTextExtracted(text, file.name);
    } catch (e) {
      if (mounted) _showFeedback('Failed to read PDF: ${e.toString()}');
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
      _showFeedback('Nothing found in clipboard');
      return;
    }
    _controller.text = text;
    widget.onTextExtracted(text, 'Clipboard');
  }

  void _onSample() {
    _controller.text = '';
    widget.onTextExtracted(kDyslexiaSampleText, 'Sample');
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void triggerUploadPdf() => _onUploadPdf();

  void triggerSample() => _onSample();

  void setText(String text) => _controller.text = text;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: bgColor(state.settings.colorTheme).withAlpha(242),
            border: const Border(bottom: BorderSide(color: Colors.black12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.accessibility_new,
                  color: Color(0xFF3D5A99), size: 28),
              const SizedBox(width: 12),
              Expanded(child: _buildInput()),
              const SizedBox(width: 8),
              _buildActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput() {
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

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _onUploadPdf,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload PDF', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3D5A99),
              side: const BorderSide(color: Color(0xFF3D5A99)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _onPaste,
            icon: const Icon(Icons.content_paste, size: 18),
            label: const Text('Paste', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3D5A99),
              side: const BorderSide(color: Color(0xFF3D5A99)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _onSample,
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: const Text('Sample', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3D5A99),
              side: const BorderSide(color: Color(0xFF3D5A99)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }
}
