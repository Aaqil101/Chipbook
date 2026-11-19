import '../models/entry.dart';
import '../models/fund.dart';
import 'ledger.dart';

/// A fund plus its approved figures, as the Home tab shows it.
class FundSnapshot {
  const FundSnapshot({required this.fund, required this.summary});

  final Fund fund;
  final LedgerSummary summary;

  /// Contributions net of reversals, in the fund's own currency.
  int get raisedMinor => summary.raisedMinorFor(fund.defaultCurrency);

  /// What is left after payouts, in the fund's own currency.
  int get balanceMinor => summary.balanceMinorFor(fund.defaultCurrency);

  /// Paid out of the fund so far, in the fund's own currency.
  int get paidOutMinor => summary.paidOutMinorFor(fund.defaultCurrency);

  /// Pending entries waiting for an organizer.
  int get pendingCount => summary.pending.length;
}

/// Everything the Home tab needs, built from a single bulk entry read.
///
/// Each fund is summarised in its own currency, so no figure ever mixes
/// currencies. Only [pendingCount] is summed across funds, and it counts
/// entries rather than money.
class HomeDashboard {
  HomeDashboard._({
    required this.funds,
    required this.pendingCount,
    required this.archivedCount,
  });

  /// Summarises [funds] from [entriesByFund], keyed by fund id.
  factory HomeDashboard.from({
    required List<Fund> funds,
    required List<Fund> archivedFunds,
    required Map<String, List<Entry>> entriesByFund,
  }) {
    return HomeDashboard.fromSummaries(
      funds: funds,
      archivedFunds: archivedFunds,
      summaries: {
        for (final fund in funds)
          fund.id: LedgerSummary.from(
            entriesByFund[fund.id] ?? const <Entry>[],
            defaultCurrency: fund.defaultCurrency,
          ),
      },
    );
  }

  /// Summarises [funds] from totals that were already built.
  factory HomeDashboard.fromSummaries({
    required List<Fund> funds,
    required List<Fund> archivedFunds,
    required Map<String, LedgerSummary> summaries,
  }) {
    final snapshots = <FundSnapshot>[
      for (final fund in funds)
        FundSnapshot(
          fund: fund,
          summary:
              summaries[fund.id] ??
              LedgerSummary.from(
                const <Entry>[],
                defaultCurrency: fund.defaultCurrency,
              ),
        ),
    ];

    return HomeDashboard._(
      funds: List<FundSnapshot>.unmodifiable(snapshots),
      pendingCount: snapshots.fold(
        0,
        (total, snapshot) => total + snapshot.pendingCount,
      ),
      archivedCount: archivedFunds.length,
    );
  }

  /// Active funds, oldest first.
  final List<FundSnapshot> funds;

  /// Pending entries across every active fund.
  final int pendingCount;

  final int archivedCount;

  bool get isEmpty => funds.isEmpty;
}
