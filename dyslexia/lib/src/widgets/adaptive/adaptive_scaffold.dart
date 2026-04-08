import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/utils/platform.dart';

class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showNavigationBar;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.leading,
    this.showNavigationBar = true,
  });

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: showNavigationBar
            ? CupertinoNavigationBar(
                middle: Text(title),
                leading: leading,
                trailing: actions != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      )
                    : null,
              )
            : null,
        child: SafeArea(
          child: Stack(
            children: [
              body,
              if (floatingActionButton != null)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: floatingActionButton!,
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: showNavigationBar
          ? AppBar(
              title: Text(title),
              leading: leading,
              actions: actions,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
