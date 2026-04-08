part of 'display_settings_bloc.dart';

class DisplaySettingsState extends Equatable {
  final DisplaySettingsModel settings;

  const DisplaySettingsState({required this.settings});

  DisplaySettingsState copyWith({DisplaySettingsModel? settings}) =>
      DisplaySettingsState(settings: settings ?? this.settings);

  @override
  List<Object?> get props => [settings];
}
