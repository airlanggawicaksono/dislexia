import 'package:flutter/material.dart';

/// Branded loading widget: owl logo + wordmark + spinner.
/// Desktop: Transparent background, compact size, dark text, purple spinner.
/// Mobile: Purple gradient background, white text, white spinner.
class AppSplash extends StatelessWidget {
  final String? message;

  const AppSplash({super.key, this.message});

  static const Color _purplePrimary = Color(0xFFB596E5);
  static const Color _textDarkDesktop = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    // ✅ 1. HAPUS Scaffold agar tidak memaksa full-screen atau menimpa header
    return Container(
      // ✅ 2. Background transparan untuk desktop, gradient ungu untuk mobile
      color: isDesktop ? Colors.transparent : null,
      decoration: isDesktop
          ? null
          : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC9B8F0),
                  Color(0xFFB596E5),
                ],
              ),
            ),
      // ✅ 3. Gunakan alignment center tanpa memaksa height double.infinity
      alignment: Alignment.center,
      child: isDesktop 
          ? _buildDesktopLayout()
          : _buildMobileLayout(),
    );
  }

  // Layout Desktop: Compact, background transparan, tidak menimpa header
  Widget _buildDesktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ Hanya mengambil tinggi sesuai konten
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo_owl.png',
          height: 80, // ✅ Ukuran lebih proporsional untuk inline/desktop
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        const Text(
          'Dyslexic.app',
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: _textDarkDesktop, 
            letterSpacing: 0.5,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: _textDarkDesktop,
            ),
          ),
        ],
        const SizedBox(height: 20),
        const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(_purplePrimary),
          ),
        ),
      ],
    );
  }

  // Layout Mobile: Tetap full-screen seperti semula
  Widget _buildMobileLayout() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo_owl.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'Dyslexic.app',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 32),
          const SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}