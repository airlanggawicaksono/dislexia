part of 'display_settings_bloc.dart';

class DisplaySettingsState extends Equatable {
  final DisplaySettingsEntity settings;

  const DisplaySettingsState({required this.settings});

  DisplaySettingsState copyWith({DisplaySettingsEntity? settings}) =>
      DisplaySettingsState(settings: settings ?? this.settings);

  @override
  List<Object?> get props => [settings];
}
