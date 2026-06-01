import 'package:equatable/equatable.dart';

import '../../../domain/entities/sidebar_section.dart';

abstract class SidebarEvent extends Equatable {
  const SidebarEvent();
  @override
  List<Object?> get props => [];
}

/// Dispatched when the user taps one of the 5 rail items.
class SidebarSectionSelected extends SidebarEvent {
  final SidebarSection section;
  const SidebarSectionSelected(this.section);
  @override
  List<Object?> get props => [section];
}
