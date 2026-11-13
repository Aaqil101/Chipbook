import 'package:flutter/foundation.dart';

import '../domain/fund_permissions.dart';
import '../models/fund.dart';
import '../models/member_role.dart';
import '../repositories/entry_repository.dart';
import '../repositories/fund_repository.dart';
import '../repositories/membership_repository.dart';
import 'ledger_controller.dart';

/// Loads the user's funds, tracks the active one, and owns its ledger.
class FundController extends ChangeNotifier {
  FundController(
    this._fundRepository,
    this._entryRepository,
    this._membershipRepository, {
    required this.userId,
  });

  final FundRepository _fundRepository;
  final EntryRepository _entryRepository;
  final MembershipRepository _membershipRepository;

  /// Signed-in user, used to look up their role in the active fund.
  final String? userId;

  List<Fund> _funds = const <Fund>[];
  Fund? _activeFund;
  LedgerController? _ledger;
  MemberRole? _role;
  bool _isLoading = true;
  String? _error;

  List<Fund> get funds => _funds;
  Fund? get activeFund => _activeFund;
  LedgerController? get ledger => _ledger;

  /// The signed-in user's role in the active fund, once loaded.
  MemberRole? get role => _role;

  /// Actions available in the active fund, or null until the role is known.
  FundPermissions? get permissions =>
      _role == null ? null : FundPermissions(_role!);

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads the funds the current user can access.
  ///
  /// Selects [preferFundId] when it is present, otherwise the first fund.
  Future<void> load({String? preferFundId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _funds = await _fundRepository.getFunds();
      final preferredIndex = _funds.indexWhere(
        (fund) => fund.id == preferFundId,
      );
      final selected = _funds.isEmpty
          ? null
          : _funds[preferredIndex == -1 ? 0 : preferredIndex];
      await _activate(selected);
    } on Object catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a fund, makes it active, and loads its empty ledger.
  Future<Fund> createFund({
    required String name,
    required String defaultCurrency,
  }) async {
    final fund = await _fundRepository.createFund(
      name: name,
      defaultCurrency: defaultCurrency,
    );

    _funds = [..._funds, fund];
    await _activate(fund);
    notifyListeners();
    return fund;
  }

  /// Switches the active fund, its role, and its entries.
  Future<void> selectFund(Fund fund) async {
    if (fund.id == _activeFund?.id) {
      return;
    }

    await _activate(fund);
    notifyListeners();
  }

  Future<void> _activate(Fund? fund) async {
    _activeFund = fund;
    _role = null;
    _ledger?.dispose();
    _ledger = fund == null
        ? null
        : LedgerController(
            _entryRepository,
            fundId: fund.id,
            currency: fund.defaultCurrency,
          );

    if (fund == null) {
      return;
    }

    _role = await _loadRole(fund.id);
    notifyListeners();
    await _ledger!.load();
  }

  Future<MemberRole?> _loadRole(String fundId) async {
    final userId = this.userId;
    if (userId == null) {
      return null;
    }

    final memberships = await _membershipRepository.getMemberships(
      fundId: fundId,
    );
    for (final membership in memberships) {
      if (membership.userId == userId) {
        return membership.role;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _ledger?.dispose();
    super.dispose();
  }
}
