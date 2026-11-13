import '../models/entry.dart';
import '../models/fund_cadence.dart';

/// The calendar period a fund's target applies to.
///
/// Boundaries follow the device's local time: weeks start on Monday, months on
/// the 1st, and years on 1 January. A one-off fund has a single period that
/// starts on the day it was created and never ends, so its target is a
/// lifetime goal.
class FundPeriod {
  const FundPeriod({
    required this.cadence,
    required this.start,
    this.endExclusive,
  });

  /// The period containing [now] for a fund created at [createdAt].
  factory FundPeriod.current(
    FundCadence cadence, {
    required DateTime now,
    required DateTime createdAt,
  }) {
    if (cadence == FundCadence.oneOff) {
      final created = createdAt.toLocal();
      return FundPeriod(
        cadence: cadence,
        start: DateTime(created.year, created.month, created.day),
      );
    }

    final local = now.toLocal();
    final DateTime start;
    final DateTime endExclusive;

    switch (cadence) {
      case FundCadence.weekly:
        // DateTime normalizes out-of-range days, so a Monday in the previous
        // month or year needs no special handling.
        final monday = local.day - (local.weekday - DateTime.monday);
        start = DateTime(local.year, local.month, monday);
        endExclusive = DateTime(local.year, local.month, monday + 7);
      case FundCadence.monthly:
        start = DateTime(local.year, local.month);
        endExclusive = DateTime(local.year, local.month + 1);
      case FundCadence.yearly:
        start = DateTime(local.year);
        endExclusive = DateTime(local.year + 1);
      case FundCadence.oneOff:
        throw StateError('one-off funds are handled above');
    }

    return FundPeriod(
      cadence: cadence,
      start: start,
      endExclusive: endExclusive,
    );
  }

  final FundCadence cadence;

  /// First instant of the period, in local time.
  final DateTime start;

  /// First instant after the period, or null for a one-off fund.
  final DateTime? endExclusive;

  /// Last day inside the period, or null when the period never ends.
  DateTime? get endInclusive {
    final end = endExclusive;
    if (end == null) {
      return null;
    }
    return DateTime(end.year, end.month, end.day - 1);
  }

  /// Whether [moment] falls inside this period.
  bool contains(DateTime moment) {
    final end = endExclusive;
    return !moment.isBefore(start) && (end == null || moment.isBefore(end));
  }

  /// Entries that count toward this period.
  ///
  /// A reversal is attributed to the period of the entry it reverses, so
  /// correcting an old entry adjusts that period instead of shrinking the
  /// current one. A reversal whose target is not loaded falls back to its own
  /// date.
  List<Entry> entriesFrom(Iterable<Entry> entries) {
    final all = entries.toList(growable: false);
    final byId = {for (final entry in all) entry.id: entry};
    return [
      for (final entry in all)
        if (contains(_attributedAt(entry, byId))) entry,
    ];
  }

  static DateTime _attributedAt(Entry entry, Map<String, Entry> byId) {
    final targetId = entry.reversesEntryId;
    if (targetId == null) {
      return entry.createdAt;
    }
    return byId[targetId]?.createdAt ?? entry.createdAt;
  }
}
