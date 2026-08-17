import 'package:easy_localization/easy_localization.dart';

import '../../features/sidebar/domain/entities/sidebar_section.dart';

/// Localized display name for a feature. The [SidebarSection] enum value stays
/// the stable logic key (used for palettes, routing, etc.) — only the text
/// shown to the user is translated here.
String featureLabel(SidebarSection section) => switch (section) {
      SidebarSection.reader => 'feature.reader'.tr(),
      SidebarSection.summarize => 'feature.summarize'.tr(),
      SidebarSection.define => 'feature.define'.tr(),
      SidebarSection.professionalize => 'feature.professionalize'.tr(),
      SidebarSection.screening => 'feature.screening'.tr(),
    };
