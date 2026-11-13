/// How often a fund's collection period repeats.
///
/// [code] matches the `fund_cadence` enum in Postgres and [label] is the
/// user-facing name.
enum FundCadence {
  oneOff('one_off', 'One-off', 'A single collection with no reset'),
  weekly('weekly', 'Weekly', 'Totals reset every Monday'),
  monthly('monthly', 'Monthly', 'Totals reset on the 1st'),
  yearly('yearly', 'Yearly', 'Totals reset on 1 January');

  const FundCadence(this.code, this.label, this.rollover);

  final String code;
  final String label;

  /// When the next period starts, shown under the cadence picker.
  final String rollover;

  /// Whether the fund repeats on a calendar period.
  bool get isRecurring => this != FundCadence.oneOff;

  /// Heading used for the current period's progress.
  String get periodTitle => switch (this) {
    FundCadence.oneOff => 'Goal',
    FundCadence.weekly => 'This week',
    FundCadence.monthly => 'This month',
    FundCadence.yearly => 'This year',
  };

  /// What a target amount applies to.
  String get targetScope => switch (this) {
    FundCadence.oneOff => 'Goal for the whole fund',
    FundCadence.weekly => 'Goal for each week',
    FundCadence.monthly => 'Goal for each month',
    FundCadence.yearly => 'Goal for each year',
  };

  static FundCadence fromCode(String code) {
    for (final cadence in values) {
      if (cadence.code == code) {
        return cadence;
      }
    }
    throw ArgumentError.value(code, 'code', 'unknown fund cadence');
  }
}
