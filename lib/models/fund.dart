import 'fund_cadence.dart';

/// A fundraising ledger shared by a group.
class Fund {
  const Fund({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    required this.createdBy,
    required this.createdAt,
    this.cadence = FundCadence.oneOff,
    this.targetMinor,
    this.archivedAt,
  });

  final String id;
  final String name;

  /// ISO 4217 code every entry and the target are recorded in.
  final String defaultCurrency;

  final String createdBy;
  final DateTime createdAt;

  /// How often the fund's collection period repeats.
  final FundCadence cadence;

  /// Optional goal in [defaultCurrency] for the current period.
  ///
  /// Null when the fund has no target. A one-off fund's target is a lifetime
  /// goal because its single period never rolls over.
  final int? targetMinor;

  /// When the fund was archived, or null while it is in use.
  ///
  /// Archived funds keep their ledger but accept no new entries and are
  /// hidden from the active fund list.
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  bool get hasTarget => targetMinor != null;

  /// Returns a copy with a new [cadence] and [targetMinor].
  Fund withSettings({required FundCadence cadence, required int? targetMinor}) {
    return Fund(
      id: id,
      name: name,
      defaultCurrency: defaultCurrency,
      createdBy: createdBy,
      createdAt: createdAt,
      cadence: cadence,
      targetMinor: targetMinor,
      archivedAt: archivedAt,
    );
  }
}
