/// A fundraising ledger shared by a group.
class Fund {
  const Fund({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    required this.createdBy,
    required this.createdAt,
    this.archivedAt,
  });

  final String id;
  final String name;

  /// ISO 4217 code used for new entries in this fund.
  final String defaultCurrency;

  final String createdBy;
  final DateTime createdAt;

  /// When the fund was archived, or null while it is in use.
  ///
  /// Archived funds keep their ledger but accept no new entries and are
  /// hidden from the active fund list.
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;
}
