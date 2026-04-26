import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class AdaptiveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;
  final Color? color;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (_isCupertino) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: onPressed,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(data: const IconThemeData(color: CupertinoColors.white), child: icon),
              const SizedBox(width: 8),
              DefaultTextStyle(
                style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w600),
                child: label,
              ),
            ],
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF4C658A),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: icon,
      label: label,
      onPressed: onPressed,
    );
  }
}

class AdaptiveIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const AdaptiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (_isCupertino) {
      return CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: onPressed,
        child: icon,
      );
    }

    return IconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}
