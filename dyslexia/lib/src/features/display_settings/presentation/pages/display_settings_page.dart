import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/list_translation_locale.dart';
import '../../../../core/widgets/settings/accessibility_toggles.dart';
import '../../../../core/widgets/settings/color_selector.dart';
import '../../../../core/widgets/settings/font_selector.dart';
import '../../../../core/widgets/settings/live_preview.dart';
import '../../../../core/widgets/settings/typography_sliders.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../domain/entities/display_settings_entity.dart';
import '../bloc/display_settings/display_settings_bloc.dart';

class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  static const _presetLabels = {
    DisplayPreset.defaultPreset: 'Default',
    DisplayPreset.dyslexiaFriendly: 'Dyslexia Friendly',
    DisplayPreset.highContrast: 'High Contrast',
    DisplayPreset.lightBlueTheme: 'Light Blue',
    DisplayPreset.greyTheme: 'Grey',
    DisplayPreset.lavenderTheme: 'Lavender',
    DisplayPreset.whiteTheme: 'White',
    DisplayPreset.skyBlueTheme: 'Sky Blue',
    DisplayPreset.mintGreenTheme: 'Mint Green',
    DisplayPreset.peachTheme: 'Peach',
  };

  static const _presetSubtitles = {
    DisplayPreset.defaultPreset: 'OpenDyslexic - Cream - 18pt',
    DisplayPreset.dyslexiaFriendly: 'OpenDyslexic - Cream - 20pt - 2.0x',
    DisplayPreset.highContrast: 'Plus Jakarta Sans - White - 22pt',
    DisplayPreset.lightBlueTheme: 'Sassoon Primary - Light Blue - 18pt',
    DisplayPreset.greyTheme: 'Tahoma - Grey - 18pt',
    DisplayPreset.lavenderTheme: 'Sassoon Primary - Lavender - 18pt',
    DisplayPreset.whiteTheme: 'OpenDyslexic - White - 18pt',
    DisplayPreset.skyBlueTheme: 'Plus Jakarta Sans - Sky Blue - 18pt',
    DisplayPreset.mintGreenTheme: 'Lexend - Mint Green - 18pt',
    DisplayPreset.peachTheme: 'Sassoon Primary - Peach - 18pt',
  };

  // Palette Ungu
  static const _purplePrimary = Color(0xFFB596E5);
  static const _purpleLight = Color(0xFFE0D5F7);
  static const _purpleText = Color(0xFF8B6FB8);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // === BACKGROUND 2 LAPIS UNGU ===
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.35,
              decoration: const BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_purpleLight, _purplePrimary],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          // === KONTEN UTAMA ===
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
                  builder: (context, state) {
                    final s = state.settings;
                    final bloc = context.read<DisplaySettingsBloc>();
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      children: [
                        _buildSectionLabel('settings.livePreview'.tr()),
                        _buildSettingCard(const LivePreview()),
                        const SizedBox(height: 24),

                        _buildSectionLabel('settings.font'.tr()),
                        // Compact chips: this full-page card is wide, so the
                        // 3-column grid cells balloon past 100px tall. The
                        // compact Wrap flows small chips (shell-panel density)
                        // to fill the available width instead.
                        _buildSettingCard(const FontSelector(compact: true)),
                        const SizedBox(height: 24),

                        _buildSectionLabel('settings.backgroundColor'.tr()),
                        _buildSettingCard(const ColorSelector(compact: true)),
                        const SizedBox(height: 24),

                        _buildSectionLabel('settings.typography'.tr()),
                        _buildSettingCard(const TypographySliders()),
                        const SizedBox(height: 24),

                        _buildSectionLabel('settings.accessibility'.tr()),
                        _buildSettingCard(const AccessibilityToggles()),
                        const SizedBox(height: 24),

                        _buildSectionLabel('settings.language'.tr()),
                        _buildSettingCard(const _LanguageSelector()),
                        const SizedBox(height: 24),

                        _buildSectionLabel('settings.quickPresets'.tr()),
                        ...DisplayPreset.values.map((p) => _PresetTile(
                              label: _presetLabels[p] ?? '',
                              subtitle: _presetSubtitles[p] ?? '',
                              selected: s.preset == p,
                              onTap: () => bloc.add(ApplyPresetEvent(p)),
                            )),
                        const SizedBox(height: 24),

                        _buildSectionLabel('settings.account'.tr()),
                        const _LogoutButton(),
                        const SizedBox(height: 32),
                      ],
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
          Expanded(
            child: Text(
              'settings.title'.tr(),
              style: const TextStyle(
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

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _purpleText,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Switches the whole app UI language. `easy_localization` persists the
/// choice and rebuilds on `setLocale`, so no extra bloc/storage is needed.
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  static const _purplePrimary = Color(0xFFB596E5);
  static const _purpleLight = Color(0xFFE0D5F7);

  @override
  Widget build(BuildContext context) {
    // Compare on language code only — startLocale/country variants
    // ('en'/'en-US') must still register as the same choice.
    final current = context.locale.languageCode;
    return Row(
      children: [
        Expanded(
          child: _langTile(context, 'English', 'English', englishLocale,
              current == englishLocale.languageCode),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _langTile(context, 'Bahasa Indonesia', 'Indonesia',
              indonesiaLocale, current == indonesiaLocale.languageCode),
        ),
      ],
    );
  }

  Widget _langTile(BuildContext context, String label, String short,
      Locale locale, bool selected) {
    return Semantics(
      label: 'Language $label',
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.setLocale(locale),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? _purpleLight : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _purplePrimary : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: _purplePrimary, size: 18),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? _purplePrimary : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  Future<void> _confirmAndLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('logout.confirmTitle'.tr()),
        content: Text('logout.confirmBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.black54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('logout.button'.tr()),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthBloc>().add(const LogoutEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'logout.button'.tr(),
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _confirmAndLogout(context),
          borderRadius: BorderRadius.circular(16),
          child: ExcludeSemantics(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF5350)),
                  const SizedBox(width: 12),
                  Text('logout.button'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFFEF5350))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  
  const _PresetTile({
    required this.label, 
    required this.subtitle, 
    required this.selected, 
    required this.onTap,
  });

 
  static const Color _purplePrimary = Color(0xFFB596E5);
  static const Color _purpleLight = Color(0xFFE0D5F7);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Preset $label',
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ExcludeSemantics(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? _purpleLight : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? _purplePrimary : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected ? _purplePrimary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? _purplePrimary.withOpacity(0.7) : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
           
            if (selected)
              const Icon(
                Icons.check_circle_rounded, 
                color: Color(0xFFB596E5), 
                size: 22,
                ),
            ],
          ),
          ),
          ),
        ),
      ),
    );
  }
}