import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../routes/app_route_path.dart';
import '../widgets/action_tile.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // TODO(fep): ugly colors, move to theme
  static const _bgColor = Color(0xFFF5F0E8);
  static const _iconBgColor = Color(0xFFE2DDD4);
  static const _iconColor = Color(0xFF3D5A99);

  Future<void> _pasteFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!context.mounted) return;
    if (text.isEmpty) {
      showAdaptiveFeedback(context, 'Nothing found in clipboard');
      return;
    }
    context.pushNamed(
      AppRoute.textPad.name,
      extra: {'text': text, 'sourceName': 'Clipboard'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      ActionTile(
        icon: _isCupertino
            ? CupertinoIcons.doc_on_clipboard
            : Icons.content_paste_rounded,
        label: 'Paste from Clipboard',
        onTap: () => _pasteFromClipboard(context),
      ),
      ActionTile(
        icon: _isCupertino
            ? CupertinoIcons.cloud_upload
            : Icons.upload_file_rounded,
        label: 'Upload File',
        onTap: () => context.pushNamed(AppRoute.upload.name),
      ),
      ActionTile(
        icon: _isCupertino
            ? CupertinoIcons.camera
            : Icons.camera_alt_rounded,
        label: 'Scan with Camera',
        onTap: () => context.pushNamed(AppRoute.scanPaste.name),
      ),
      ActionTile(
        icon: _isCupertino
            ? CupertinoIcons.viewfinder
            : Icons.center_focus_strong_rounded,
        label: 'Lens',
        onTap: () => context.pushNamed(AppRoute.lens.name),
      ),
      ActionTile(
        icon: _isCupertino
            ? CupertinoIcons.text_badge_checkmark
            : Icons.summarize_rounded,
        label: 'Summarize',
        onTap: () => context.pushNamed(AppRoute.summarize.name),
      ),
      ActionTile(
        icon: _isCupertino ? CupertinoIcons.book : Icons.menu_book_rounded,
        label: 'Define',
        onTap: () => context.pushNamed(AppRoute.define.name),
      ),
      ActionTile(
        icon: _isCupertino
            ? CupertinoIcons.briefcase
            : Icons.business_center_rounded,
        label: 'Professionalize',
        onTap: () => context.pushNamed(AppRoute.professionalize.name),
      ),
      ActionTile(
        icon: _isCupertino
            ? CupertinoIcons.checkmark_seal
            : Icons.fact_check_rounded,
        label: 'Pre-Screening',
        onTap: () => context.pushNamed(AppRoute.screening.name),
      ),
    ];

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AdaptiveIconButton(
                  icon: Icon(
                    _isCupertino
                        ? CupertinoIcons.settings
                        : Icons.settings_rounded,
                    color: Colors.black54,
                  ),
                  onPressed: () =>
                      context.pushNamed(AppRoute.displaySettings.name),
                ),
              ),
            ),
            // Top: hero, roughly the upper half.
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: _iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        size: 38,
                        color: _iconColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Add your text to get started',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Paste text, upload a file, or scan a\ndocument with your camera',
                      style: TextStyle(
                          fontSize: 14, color: Colors.black45, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // Bottom: half-page action list, same colour, faded as it scrolls.
            Expanded(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.06, 0.9, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  itemCount: actions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => actions[i],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;
