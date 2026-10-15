import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../routes/app_route_path.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _headerColorStart = Color(0xFFC9B8F0);
  static const _headerColorEnd = Color(0xFFB596E5);
  static const _headerBottomLayer = Color(0xFFD7C8FC);

  static const Map<String, _FeaturePalette> _palettes = {
    'summarize': _FeaturePalette(
      color: Color(0xFFFFE0B2),
      tint: Color(0xFFFFF3E0),
      onTint: Color(0xFF6B4423),
    ),
    'professionalize': _FeaturePalette(
      color: Color(0xFF90CAF9),
      tint: Color(0xFFE3F2FD),
      onTint: Color(0xFF1E3A5F),
    ),
    'define': _FeaturePalette(
      color: Color(0xFFFFAB91),
      tint: Color(0xFFFBE9E7),
      onTint: Color(0xFF5F2A1F),
    ),
    'screening': _FeaturePalette(
      color: Color(0xFFA5D6A7),
      tint: Color(0xFFE8F5E9),
      onTint: Color(0xFF1B5E20),
    ),
    'lens': _FeaturePalette(
      color: Color(0xFFFFE082),
      tint: Color(0xFFFFF8E1),
      onTint: Color(0xFF5D4037),
    ),
    'camera': _FeaturePalette(
      color: Color(0xFFB39DDB),
      tint: Color(0xFFEDE7F6),
      onTint: Color(0xFF4A148C),
    ),
    'default': _FeaturePalette(
      color: Color(0xFFB39DDB),
      tint: Color(0xFFEDE7F6),
      onTint: Color(0xFF3E3A7A),
    ),
  };

  _FeaturePalette _getPaletteForKey(String key) {
    return _palettes[key] ?? _palettes['default']!;
  }

  Future<void> _pasteFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!context.mounted) return;
    if (text.isEmpty) {
      showAdaptiveFeedback(context, 'feedback.clipboardEmpty'.tr());
      return;
    }
    context.pushNamed(
      AppRoute.textPad.name,
      extra: {'text': text, 'sourceName': 'Clipboard'},
    );
  }

  Widget _getIconForKey(String key, Color iconColor) {
    const double iconSize = 35.0;

    switch (key) {
      case 'summarize':
        return Image.asset('assets/images/summarize.png', width: iconSize, height: iconSize);
      case 'define':
        return Image.asset('assets/images/define.png', width: iconSize, height: iconSize);
      case 'professionalize':
        return Image.asset('assets/images/profesionalize.png', width: iconSize, height: iconSize);
      case 'lens':
        return Image.asset('assets/images/lens.png', width: iconSize, height: iconSize);
      case 'camera':
        return Image.asset('assets/images/scanner.png', width: iconSize, height: iconSize);
      case 'reader':
        return Image.asset('assets/images/reader.png', width: iconSize, height: iconSize);
      case 'screening':
        return Icon(
          _isCupertino ? CupertinoIcons.checkmark_seal : Icons.fact_check_rounded,
          size: iconSize,
          color: const Color(0xFFA5D6A7),
        );
      default:
        return Icon(Icons.help_outline, size: iconSize, color: iconColor);
    }
  }

  Widget _buildActionCard({
    required String key,
    required String label,
    required VoidCallback onTap,
  }) {
    final palette = _getPaletteForKey(key);
    
    return Semantics(
      label: label,
      button: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white,
              Colors.white,
              palette.tint,
              palette.color,
            ],
            stops: const [0.0, 0.3, 0.65, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _getIconForKey(key, palette.color),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: palette.onTint,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Icon(
                    _isCupertino ? CupertinoIcons.chevron_right : Icons.chevron_right,
                    color: palette.onTint.withOpacity(0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PERBAIKAN UTAMA: 
    // Membaca context.locale memaksa widget ini untuk segera di-rebuild 
    // ketika bahasa diganti, mengatasi masalah delay atau label yang tidak berubah.
    final currentLocale = context.locale;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    final List<Map<String, String>> actions = [
      {'key': 'summarize', 'route': AppRoute.summarize.name},
      {'key': 'define', 'route': AppRoute.define.name},
      {'key': 'professionalize', 'route': AppRoute.professionalize.name},
      {'key': 'screening', 'route': AppRoute.screening.name},
      {'key': 'lens', 'route': AppRoute.lens.name},
      {'key': 'camera', 'route': AppRoute.scanPaste.name},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (!isDesktop) ...[
              SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 110,
                      decoration: const BoxDecoration(
                        color: _headerBottomLayer,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_headerColorStart, _headerColorEnd],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pushNamed(AppRoute.displaySettings.name),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: Colors.black87,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo_owl.png',
                                height: 75,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 56),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      'Reazy',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.pushNamed(AppRoute.displaySettings.name),
                      icon: const Icon(Icons.settings_rounded, color: Colors.black87, size: 28),
                      tooltip: 'action.settings'.tr(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black12),
            ],
          
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 600 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'landing.exploreTools'.tr(),
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...actions.map((action) {
                          final key = action['key']!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildActionCard(
                              key: key,
                              label: 'feature.$key'.tr(),
                              onTap: () => context.pushNamed(action['route']!),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePalette {
  final Color color;
  final Color tint;
  final Color onTint;

  const _FeaturePalette({
    required this.color,
    required this.tint,
    required this.onTint,
  });
}

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;