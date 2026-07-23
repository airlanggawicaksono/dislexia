import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route_path.dart';
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
          // HEADER DENGAN BACKGROUND UNGU
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT dengan Grid Layout
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                children: [
                  const Text(
                    'What do you want to do today?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Grid untuk 3 kartu pertama (Reader, Define, Summarize)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _buildFeatureCard(section: SidebarSection.reader, onTap: () => _navigateToFeature(context, SidebarSection.reader))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildFeatureCard(section: SidebarSection.define, onTap: () => _navigateToFeature(context, SidebarSection.define))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildFeatureCard(section: SidebarSection.summarize, onTap: () => _navigateToFeature(context, SidebarSection.summarize))),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Grid untuk 2 kartu kedua (Professionalize, Screening) - di tengah
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _buildFeatureCard(section: SidebarSection.professionalize, onTap: () => _navigateToFeature(context, SidebarSection.professionalize))),
                      const SizedBox(width: 20),
                      Expanded(child: _buildFeatureCard(section: SidebarSection.screening, onTap: () => _navigateToFeature(context, SidebarSection.screening))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFeature(BuildContext context, SidebarSection section) {
    print('👆 CARD DITEKAN: ${section.label}');
    
    // 1. Update SidebarBloc agar DesktopShell tahu fitur mana yang harus ditampilkan
    context.read<SidebarBloc>().add(SidebarSectionSelected(section));
    
    // 2. Pindah ke DesktopShell
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
  }

  Widget _buildFeatureCard({required SidebarSection section, required VoidCallback onTap}) {
    final descriptions = {
      SidebarSection.reader: 'Convert any text into your preferred reading format for a more comfortable experience.',
      SidebarSection.summarize: 'Turn long passages into short, easy-to-read summaries while keeping the key ideas.',
      SidebarSection.define: 'Get clear definitions and explanations for complex terms within your text.',
      SidebarSection.professionalize: 'Rewrite your text with a clear, polished, and professional tone.',
      SidebarSection.screening: 'Analyze and pre-screen text for specific criteria, tone, or compliance.',
    };

    // Warna background icon untuk setiap fitur
    final iconColors = {
      SidebarSection.reader: const Color(0xFFB596E5),
      SidebarSection.summarize: const Color(0xFF9B7FD6),
      SidebarSection.define: const Color(0xFF8B6FB8),
      SidebarSection.professionalize: const Color(0xFF7D62A8),
      SidebarSection.screening: const Color(0xFF6F5598),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon dengan background bulat
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (iconColors[section] ?? const Color(0xFFB596E5)).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  section.materialIcon,
                  size: 32,
                  color: iconColors[section] ?? const Color(0xFFB596E5),
                ),
              ),
              const SizedBox(height: 16),
              // Judul
              Text(
                section.label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Deskripsi
              Text(
                descriptions[section] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}