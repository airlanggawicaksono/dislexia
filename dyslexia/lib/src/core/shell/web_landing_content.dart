import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/display_settings/presentation/theme/display_colors.dart';

class WebLandingContent extends StatelessWidget {
  final VoidCallback onUploadTap;
  final void Function(String text, String? source) onPasteTap;
  final void Function(String message) onCameraSnack;

  const WebLandingContent({
    super.key,
    required this.onUploadTap,
    required this.onPasteTap,
    required this.onCameraSnack,
  });

  static const _iconColor = Color(0xFF3D5A99);

  Future<void> _pasteFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!context.mounted) return;
    if (text.isEmpty) {
      showAdaptiveFeedback(context, 'Nothing found in clipboard');
      return;
    }
    onPasteTap(text, 'Clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final bg = bgColor(state.settings.colorTheme);
        final fg = fgColor(state.settings.colorTheme);
        final tileColor = fg.withValues(alpha: 0.08);
        final iconBgColor = fg.withValues(alpha: 0.12);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const Spacer(),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      size: 38,
                      color: _iconColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Add your text to get started',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Paste text, upload a file, or scan a\ndocument with your camera',
                    style: TextStyle(
                        fontSize: 14,
                        color: fg.withValues(alpha: 0.6),
                        height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  _ActionTile(
                    tileColor: tileColor,
                    fgColor: fg,
                    icon: _isCupertino
                        ? CupertinoIcons.doc_on_clipboard
                        : Icons.content_paste_rounded,
                    label: 'Paste from Clipboard',
                    onTap: () => _pasteFromClipboard(context),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    tileColor: tileColor,
                    fgColor: fg,
                    icon: _isCupertino
                        ? CupertinoIcons.cloud_upload
                        : Icons.upload_file_rounded,
                    label: 'Upload File',
                    onTap: onUploadTap,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tileColor;
  final Color fgColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tileColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    if (_isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: fgColor.withValues(alpha: 0.7)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: fgColor,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_right,
                  size: 18, color: fgColor.withValues(alpha: 0.4)),
            ],
          ),
        ),
      );
    }

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Icon(icon, size: 22, color: fgColor.withValues(alpha: 0.7)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: fgColor,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: fgColor.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

void showAdaptiveFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
