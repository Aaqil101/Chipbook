/// A fundraising ledger shared by a group.
class Fund {
  const Fund({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// ISO 4217 code used for new entries in this fund.
  final String defaultCurrency;

  final String createdBy;
  final DateTime createdAt;
}
