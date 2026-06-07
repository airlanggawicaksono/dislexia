import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Identifies the 5 top-level sections of the desktop web shell.
///
/// Each section corresponds to one rail item. The [reader] section is the
/// only currently-functional destination -- the rest are placeholders that
/// show a "Coming soon" panel until their respective features ship.
enum SidebarSection {
  reader(
    label: 'Reader',
    cupertinoIcon: CupertinoIcons.book,
    materialIcon: Icons.menu_book_rounded,
  ),
  summarize(
    label: 'Summarize',
    cupertinoIcon: CupertinoIcons.text_alignleft,
    materialIcon: Icons.summarize_rounded,
  ),
  define(
    label: 'Define',
    cupertinoIcon: CupertinoIcons.book_circle,
    materialIcon: Icons.translate_rounded,
  ),
  professionalize(
    label: 'Professionalize',
    cupertinoIcon: CupertinoIcons.person_crop_circle,
    materialIcon: Icons.auto_fix_high_rounded,
  ),
  screening(
    label: 'Screening',
    cupertinoIcon: CupertinoIcons.search,
    materialIcon: Icons.fact_check_rounded,
  );

  const SidebarSection({
    required this.label,
    required this.cupertinoIcon,
    required this.materialIcon,
  });

  final String label;
  final IconData cupertinoIcon;
  final IconData materialIcon;

  /// Whether this section is currently wired to a functional destination.
  /// Sections where this is false render a "Coming soon" placeholder.
  bool get isImplemented =>
      this == SidebarSection.reader ||
      this == SidebarSection.summarize ||
      this == SidebarSection.define ||
      this == SidebarSection.professionalize;
}
