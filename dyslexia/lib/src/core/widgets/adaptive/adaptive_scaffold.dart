import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class AdaptiveScaffold extends StatelessWidget {
  final Color? backgroundColor;
  final Widget body;
  final String? title;
  final Color? titleColor;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? iconColor;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.backgroundColor,
    this.title,
    this.titleColor,
    this.leading,
    this.actions,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (_isCupertino) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor ?? CupertinoColors.systemGroupedBackground,
        navigationBar: title != null
            ? CupertinoNavigationBar(
                backgroundColor: backgroundColor?.withValues(alpha: 0.94),
                border: null,
                leading: leading,
                middle: Text(
                  title!,
                  style: TextStyle(
                    color: titleColor ?? CupertinoColors.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: actions != null && actions!.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      )
                    : null,
              )
            : null,
        child: SafeArea(
          top: title != null,
          child: body,
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title != null
          ? AppBar(
              backgroundColor: backgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: iconColor ?? titleColor),
              leading: leading,
              title: Text(
                title!,
                style: TextStyle(
                  color: titleColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: actions,
            )
          : null,
      body: body,
    );
  }
}
