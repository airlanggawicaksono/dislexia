import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFont {
  AppFont._();

  static TextStyle normal = GoogleFonts.poppins(fontWeight: FontWeight.normal);
  static TextStyle bold = GoogleFonts.poppins(fontWeight: FontWeight.bold);
}

extension AppFontSize on TextStyle {
  TextStyle get s12 => copyWith(fontSize: 12);
  TextStyle get s14 => copyWith(fontSize: 14);
  TextStyle get s16 => copyWith(fontSize: 16);
}
