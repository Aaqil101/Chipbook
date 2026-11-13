import '../models/fund.dart';
import '../models/fund_cadence.dart';

/// Funds the current user can access.
abstract interface class FundRepository {
  /// Returns the funds the signed-in user belongs to.
  ///
  /// Archived funds are omitted unless [includeArchived] is set.
  Future<List<Fund>> getFunds({bool includeArchived = false});

  Future<Fund> createFund({
    required String name,
    required String defaultCurrency,
    FundCadence cadence = FundCadence.oneOff,
    int? targetMinor,
  });

  /// Changes when [fundId] repeats and its optional period target.
  ///
  /// Organizers only. Archived funds stay read-only.
  Future<Fund> updateFundSettings({
    required String fundId,
    required FundCadence cadence,
    int? targetMinor,
  });

  /// Hides [fundId] from the fund list while keeping its ledger.
  Future<void> archiveFund(String fundId);

  /// Makes an archived fund active again.
  Future<void> restoreFund(String fundId);

  /// Permanently removes [fundId]. Only allowed while it has no entries.
  Future<void> deleteFund(String fundId);
}
