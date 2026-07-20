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
  static const _textColor = Colors.white;
  
  // === PERUBAHAN: Warna ikon diubah menjadi #A29BFE ===
  static const _iconColor = Color(0xFFA29BFE); 

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

  Widget _getIconForAction(String label) {
    const double iconSize = 35; 

    switch (label) {
      // ==========================================
      // 1. IKON KUSTOM (.png) - Tampil polosan (warna asli gambar)
      // ==========================================
      case 'Summarize':
        return Image.asset('assets/images/summarize.png', width: iconSize, height: iconSize);
      case 'Define':
        return Image.asset('assets/images/define.png', width: iconSize, height: iconSize);
      case 'Professionalize':
        return Image.asset('assets/images/profesionalize.png', width: iconSize, height: iconSize);
      case 'Lens':
        return Image.asset('assets/images/lens.png', width: iconSize, height: iconSize);
      case 'Scan with Camera': 
        return Image.asset('assets/images/scanner.png', width: iconSize, height: iconSize);
      case 'Reader': 
        return Image.asset('assets/images/reader.png', width: iconSize, height: iconSize);
        
      // ==========================================
      // 2. IKON DEFAULT (Sekarang menggunakan warna #A29BFE)
      // ==========================================
      case 'Paste from Clipboard':
        return Icon(
          _isCupertino ? CupertinoIcons.doc_on_clipboard : Icons.content_paste_rounded,
          size: iconSize,
          color: _iconColor,
        );
      case 'Upload File':
        return Icon(
          _isCupertino ? CupertinoIcons.cloud_upload : Icons.upload_file_rounded,
          size: iconSize,
          color: _iconColor,
        );
      case 'Pre-Screening':
        return Icon(
          _isCupertino ? CupertinoIcons.checkmark_seal : Icons.fact_check_rounded,
          size: iconSize,
          color: _iconColor,
        );
        
      default:
        return const Icon(Icons.help_outline, size: iconSize, color: _iconColor);
    }
  }

  Widget _buildActionCard({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                SizedBox(
                  width: 43, 
                  height: 43,
                  child: Center(
                    child: _getIconForAction(label),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  _isCupertino ? CupertinoIcons.chevron_right : Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {'label': 'Summarize', 'onTap': () => context.pushNamed(AppRoute.summarize.name)},
      {'label': 'Define', 'onTap': () => context.pushNamed(AppRoute.define.name)},
      {'label': 'Professionalize', 'onTap': () => context.pushNamed(AppRoute.professionalize.name)},
      {'label': 'Pre-Screening', 'onTap': () => context.pushNamed(AppRoute.screening.name)},
      {'label': 'Lens', 'onTap': () => context.pushNamed(AppRoute.lens.name)},
      {'label': 'Paste from Clipboard', 'onTap': () => _pasteFromClipboard(context)},
      {'label': 'Upload File', 'onTap': () => context.pushNamed(AppRoute.upload.name)},
      {'label': 'Scan with Camera', 'onTap': () => context.pushNamed(AppRoute.scanPaste.name)},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
                        const Expanded(
                          child: Text(
                            'Reazy',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 56),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explore our tools:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...actions.map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildActionCard(
                        label: action['label'] as String,
                        onTap: action['onTap'] as VoidCallback,
                      ),
                    )),
                  ],
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