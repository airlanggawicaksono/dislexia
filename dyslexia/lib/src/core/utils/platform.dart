import 'dart:io';

class AppPlatform {
  AppPlatform._();

  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
}
