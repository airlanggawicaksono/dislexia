import 'package:flutter/material.dart';

/// Branded loading screen: owl logo + wordmark + spinner on the themed
/// purple background. Shown whenever the app is initializing or restoring — it
/// continues seamlessly from the native launch splash so the user never
/// sees a bare spinner or a flash of the wrong screen.
///
/// Reuse this anywhere a "starting up / please wait" state is needed
/// (auth restore, first load, etc.) instead of a plain
/// [CircularProgressIndicator].
class AppSplash extends StatelessWidget {
  /// Optional line under the wordmark (e.g. "Restoring session…").
  final String? message;

  const AppSplash({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan background gradient ungu agar konsisten dengan tema aplikasi
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFC9B8F0), // Ungu muda (sama dengan header start)
              Color(0xFFB596E5), // Ungu utama (sama dengan header end)
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Owl (sedikit diperbesar agar lebih menonjol di splash screen)
              Image.asset(
                'assets/images/logo_owl.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              
              // Wordmark dengan warna putih dan font bold
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
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70, // Putih dengan sedikit transparansi
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
        ),
      ),
    );
  }
}