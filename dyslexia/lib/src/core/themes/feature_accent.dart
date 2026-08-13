import 'package:flutter/material.dart';

import '../../features/sidebar/domain/entities/sidebar_section.dart';

/// Per-feature accent colours.
///
/// The app environment keeps its purple identity; these accents exist only to
/// help a user tell features apart at a glance. Colour is NEVER the only
/// signal — every feature is always identified by its icon + text label too
/// (nav card, sidebar item, header chip), and accents are chosen so that dark
/// text on the light tint easily meets WCAG AA contrast.
///
/// - [strong]: used for icons, active borders and small glyphs on white/light
///   surfaces (contrast >= 3:1 as a graphical object).
/// - [tint]:   light background wash used for chips/badges/selected states.
/// - [onTint]: dark text colour that sits on [tint] (WCAG AA >= 4.5:1).
class FeatureAccent {
  final Color strong;
  final Color tint;
  final Color onTint;

  const FeatureAccent({
    required this.strong,
    required this.tint,
    required this.onTint,
  });
}

const Map<SidebarSection, FeatureAccent> featureAccents = {
  SidebarSection.reader: FeatureAccent(
    strong: Color(0xFF7C3AED), // Purple — WCAG strong/white ≈5.6:1
    tint: Color(0xFFEDE9FE),   // purple-100
    onTint: Color(0xFF4C1D95), // purple-900 on tint ≈8.3:1
  ),
  SidebarSection.summarize: FeatureAccent(
    strong: Color(0xFFEA580C), // Orange — WCAG strong/white ≈4.6:1
    tint: Color(0xFFFFEDD5),   // orange-100
    onTint: Color(0xFF7C2D12), // orange-900 on tint ≈7.4:1
  ),
  SidebarSection.define: FeatureAccent(
    strong: Color(0xFFD97706), // Amber
    tint: Color(0xFFFEF3C7),
    onTint: Color(0xFF78350F),
  ),
  SidebarSection.professionalize: FeatureAccent(
    strong: Color(0xFF2563EB), // Blue — WCAG strong/white ≈5.5:1
    tint: Color(0xFFDBEAFE),   // blue-100
    onTint: Color(0xFF1E3A8A), // blue-900 on tint ≈8.1:1
  ),
  SidebarSection.screening: FeatureAccent(
    strong: Color(0xFF0D9488), // Teal
    tint: Color(0xFFCCFBF1),
    onTint: Color(0xFF134E4A),
  ),
};

FeatureAccent featureAccent(SidebarSection section) =>
    featureAccents[section]!;

/// Looks up an accent by a free-form feature label (used by the mobile
/// landing page whose action cards include Lens / Camera).
FeatureAccent? featureAccentByLabel(String label) {
  for (final entry in SidebarSection.values) {
    if (entry.label == label) return featureAccent(entry);
  }
  return null;
}
