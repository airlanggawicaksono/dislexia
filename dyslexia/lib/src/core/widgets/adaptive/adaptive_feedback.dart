import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

void showAdaptiveFeedback(BuildContext context, String message) {
  if (_isCupertino) {
    _showCupertinoToast(context, message);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

void _showCupertinoToast(BuildContext context, String message) {
  final overlay = Navigator.of(context).overlay;
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CupertinoToast(
      message: message,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _CupertinoToast extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _CupertinoToast({required this.message, required this.onDismiss});

  @override
  State<_CupertinoToast> createState() => _CupertinoToastState();
}

class _CupertinoToastState extends State<_CupertinoToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 60,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey.darkColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.message,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
