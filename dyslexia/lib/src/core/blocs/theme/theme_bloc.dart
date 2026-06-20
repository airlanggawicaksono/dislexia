import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(false)) {
    on<LightThemeEvent>(_lightTheme);
    on<DarkThemeEvent>(_darkTheme);
  }

  void _lightTheme(LightThemeEvent event, Emitter<ThemeState> emit) {
    emit(const ThemeState(false));
  }

  void _darkTheme(DarkThemeEvent event, Emitter<ThemeState> emit) {
    emit(const ThemeState(true));
  }
}

