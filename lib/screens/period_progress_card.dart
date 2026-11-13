import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/fund_period.dart';
import '../domain/ledger.dart';
import '../domain/money.dart';
import '../models/entry.dart';
import '../models/fund.dart';

/// Progress toward the fund's target for the current calendar period.
///
/// Only approved contributions count, so payouts never inflate progress. A
/// one-off fund with no target shows nothing, which is the plain ledger case.
class PeriodProgressCard extends StatelessWidget {
  const PeriodProgressCard({
    super.key,
    required this.fund,
    required this.entries,
    this.now,
  });

  final Fund fund;

  /// Every entry loaded for the fund.
  final List<Entry> entries;

  /// Clock override for tests; defaults to the device's local time.
  final DateTime? now;

  /// Whether [fund] has a period or target worth showing.
  static bool shouldShow(Fund fund) =>
      fund.cadence.isRecurring || fund.hasTarget;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(fund)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final period = FundPeriod.current(
      fund.cadence,
      now: now ?? DateTime.now(),
      createdAt: fund.createdAt,
    );
    final summary = LedgerSummary.from(
      period.entriesFrom(entries),
      defaultCurrency: fund.defaultCurrency,
    );
    final raised = summary.raisedMinorFor(fund.defaultCurrency);
    final target = fund.targetMinor;
    final progress = target == null ? null : (raised / target).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fund.cadence.periodTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(_rangeLabel(period), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(
              Money.format(raised, currency: fund.defaultCurrency),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              target == null
                  ? 'raised in this period'
                  : 'of ${Money.format(target, currency: fund.defaultCurrency)}'
                        ' · ${_progressLabel(raised, target)}',
              style: theme.textTheme.bodySmall,
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _progressLabel(int raised, int target) {
    if (raised >= target) {
      return 'target reached';
    }
    return '${(raised * 100) ~/ target}% of target';
  }

  String _rangeLabel(FundPeriod period) {
    final format = DateFormat.yMMMd();
    final end = period.endInclusive;
    if (end == null) {
      return 'Since ${format.format(period.start)}';
    }
    return '${format.format(period.start)} – ${format.format(end)}';
  }
}
