import '../models/fund.dart';

/// Funds the current user can access.
abstract interface class FundRepository {
  /// Returns only funds the signed-in user belongs to.
  Future<List<Fund>> getFunds();

  Future<Fund> createFund({
    required String name,
    required String defaultCurrency,
  });
}
