enum SummaryLevel {
  pct10('10pct'),
  pct30('30pct'),
  pct50('50pct'),
  pct70('70pct'),
  pct90('90pct');

  final String apiValue;
  const SummaryLevel(this.apiValue);

  static SummaryLevel get defaultLevel => SummaryLevel.pct50;
}
