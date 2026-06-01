import 'package:equatable/equatable.dart';

import '../../../domain/entities/sidebar_section.dart';

class SidebarState extends Equatable {
  final SidebarSection section;
  const SidebarState({this.section = SidebarSection.reader});

  SidebarState copyWith({SidebarSection? section}) =>
      SidebarState(section: section ?? this.section);

  @override
  List<Object?> get props => [section];
}
