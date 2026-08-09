import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route_path.dart';
import '../../../../core/themes/feature_accent.dart';
import '../../../../features/sidebar/domain/entities/sidebar_section.dart';
import '../../../../features/auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../../features/sidebar/presentation/bloc/sidebar/sidebar_bloc.dart';
import '../../../../features/sidebar/presentation/bloc/sidebar/sidebar_event.dart';

class DesktopLandingPage extends StatelessWidget {
  const DesktopLandingPage({super.key});

  static const _headerColorStart = Color(0xFFC9B8F0);
  static const _headerColorEnd = Color(0xFFB596E5);
  static const _headerBottomLayer = Color(0xFFD7C8FC);
  static const _textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    if (!isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.goNamed(AppRoute.landing.name);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        backgroundColor: Colors.white,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER DENGAN BACKGROUND UNGU (Welcome Screen)
          Container(
            width: double.infinity,
            child: Stack(
              children: [
                Container(
                  height: 110,
                  decoration: const BoxDecoration(
                    color: _headerBottomLayer,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                  ),
                ),
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_headerColorStart, _headerColorEnd]),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  ),
                ),
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    children: [
                      Image.asset('assets/images/logo_owl.png', height: 60, width: 60, fit: BoxFit.contain),
                      const SizedBox(width: 16),
                      const Text('Dyslexic.app', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textColor, letterSpacing: 0.5)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
                        child: IconButton(
                          onPressed: () => context.pushNamed(AppRoute.displaySettings.name),
                          icon: const Icon(Icons.settings_rounded, color: Colors.black87, size: 24),
                          tooltip: 'Settings',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
                        child: IconButton(
                          onPressed: () {
                            context.read<AuthBloc>().add(const LogoutEvent());
                            context.goNamed(AppRoute.auth.name);
                          },
                          icon: const Icon(Icons.logout_rounded, color: Colors.black87, size: 24),
                          tooltip: 'Logout',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT (Kartu-kartu fitur)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('What do you want to do today?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 24),
                      ...SidebarSection.values.map((section) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFeatureCard(
                            section: section,
                            onTap: () {
                              print('👆 CARD DITEKAN: ${section.label}');
                              
                              // 1. Update SidebarBloc agar DesktopShell tahu fitur mana yang harus ditampilkan
                              context.read<SidebarBloc>().add(SidebarSectionSelected(section));
                              
                              // 2. Pindah ke DesktopShell (PATH HARUS SAMA PERSIS DENGAN APP_ROUTE_CONF)
                              try {
                                context.go('/desktop-shell');
                              } catch (e) {
                                print('❌ ERROR NAVIGASI: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal membuka halaman: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required SidebarSection section, required VoidCallback onTap}) {
    final descriptions = {
      SidebarSection.reader: 'Convert any text into your preferred reading format for a more comfortable experience.',
      SidebarSection.summarize: 'Turn long passages into short, easy-to-read summaries while keeping the key ideas.',
      SidebarSection.define: 'Get clear definitions and explanations for complex terms within your text.',
      SidebarSection.professionalize: 'Rewrite your text with a clear, polished, and professional tone.',
      SidebarSection.screening: 'Analyze and pre-screen text for specific criteria, tone, or compliance.',
    };

    // Each feature card is colour-coded with its own accent, always paired
    // with the feature icon + text label (never colour alone).
    final accent = featureAccent(section);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Semantics(
        // Label carries the full card text; the visual copy below the
        // InkWell is excluded so it isn't announced a second time. The
        // InkWell itself keeps its button + tap action semantics.
        label: '${section.label}: ${descriptions[section] ?? ''}',
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          highlightColor: Colors.grey.withOpacity(0.1),
          splashColor: accent.strong.withValues(alpha: 0.15),
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: accent.tint, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Icon(section.materialIcon, size: 28, color: accent.strong)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(section.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                          const SizedBox(width: 10),
                          // Small accent chip reinforces the feature colour
                          // alongside the label text.
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.tint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              section.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: accent.onTint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(descriptions[section] ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}