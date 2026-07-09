/// Definition depth tiers. Reuses summarize's pct labels as a familiar dial,
/// but higher tier = MORE explanation layers (core → example → usage →
/// related words → nuance), not more length. Values match the backend enum.
enum DefineLevel {
  pct10('10pct'),
  pct30('30pct'),
  pct50('50pct'),
  pct70('70pct'),
  pct90('90pct');

  final String apiValue;
  const DefineLevel(this.apiValue);

  static DefineLevel get defaultLevel => DefineLevel.pct50;
}
