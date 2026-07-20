import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/reader_text_display.dart';
import '../../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../../features/display_settings/presentation/theme/display_colors.dart';
import '../../../../routes/app_route_path.dart';

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class TextPadPage extends StatelessWidget {
  final String text;
  final String? sourceName;

  const TextPadPage({super.key, required this.text, this.sourceName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final s = state.settings;
        final bg = bgColor(s.colorTheme);
        final fg = fgColor(s.colorTheme);

        return AdaptiveScaffold(
          backgroundColor: bg,
          title: sourceName ?? 'Text Pad',
          titleColor: fg,
          iconColor: fg,
          actions: [
            AdaptiveIconButton(
              icon: Icon(
                _isCupertino ? CupertinoIcons.settings : Icons.settings_rounded,
                color: fg,
              ),
              tooltip: 'Display settings',
              onPressed: () => context.pushNamed(AppRoute.displaySettings.name),
            ),
            AdaptiveIconButton(
              icon: Icon(
                _isCupertino ? CupertinoIcons.doc_on_doc : Icons.copy_rounded,
                color: fg,
              ),
              tooltip: 'Copy all',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                showAdaptiveFeedback(context, 'Copied to clipboard');
              },
            ),
          ],
          body: Column(
            children: [
              Expanded(
                child: ReaderTextDisplay(
                  text: text,
                  settings: s,
                  fgColor: fg,
                  bgColor: bg,
                ),
              ),
              // Shoot the captured/pasted text straight into an LLM feature.
              if (text.trim().isNotEmpty) _SendToBar(text: text, bg: bg, fg: fg),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom action bar: send the current text into Summarize / Define /
/// Professionalize with it pre-filled.
class _SendToBar extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _SendToBar({required this.text, required this.bg, required this.fg});

  void _send(BuildContext context, AppRoute route) =>
      context.pushNamed(route.name, extra: {'text': text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: fg.withValues(alpha: 0.12))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: _SendButton(
                    icon: Icons.summarize_rounded,
                    label: 'Summarize',
                    onTap: () => _send(context, AppRoute.summarize)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SendButton(
                    icon: Icons.menu_book_rounded,
                    label: 'Define',
                    onTap: () => _send(context, AppRoute.define)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SendButton(
                    icon: Icons.business_center_rounded,
                    label: 'Formalize',
                    onTap: () => _send(context, AppRoute.professionalize)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SendButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      // DIUBAH: Menggunakan warna ungu tema aplikasi
      color: const Color(0xFFB596E5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}