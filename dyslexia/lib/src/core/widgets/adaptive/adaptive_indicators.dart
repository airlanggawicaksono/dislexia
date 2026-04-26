import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class AdaptiveProgressIndicator extends StatelessWidget {
  final Color? color;

  const AdaptiveProgressIndicator({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    if (_isCupertino) {
      return CupertinoActivityIndicator(color: color);
    }
    return CircularProgressIndicator(color: color);
  }
}
