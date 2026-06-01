import 'package:flutter_bloc/flutter_bloc.dart';

import 'sidebar_event.dart';
import 'sidebar_state.dart';

/// Owns the currently selected top-level sidebar section.
///
/// Pure routing state -- no side effects, no persistence. The shell
/// rebuilds its content area based on [SidebarState.section] and the
/// [SidebarSection.isImplemented] flag decides whether to render the
/// real destination or a "Coming soon" placeholder.
class SidebarBloc extends Bloc<SidebarEvent, SidebarState> {
  SidebarBloc() : super(const SidebarState()) {
    on<SidebarSectionSelected>(_onSectionSelected);
  }

  void _onSectionSelected(
      SidebarSectionSelected event, Emitter<SidebarState> emit) {
    if (event.section == state.section) return;
    emit(state.copyWith(section: event.section));
  }
}
