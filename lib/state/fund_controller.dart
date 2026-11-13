import 'package:flutter/foundation.dart';

import '../models/fund.dart';
import '../repositories/entry_repository.dart';
import '../repositories/fund_repository.dart';
import 'ledger_controller.dart';

/// Loads the user's funds, tracks the active one, and owns its ledger.
class FundController extends ChangeNotifier {
  FundController(this._fundRepository, this._entryRepository);

  final FundRepository _fundRepository;
  final EntryRepository _entryRepository;

  List<Fund> _funds = const <Fund>[];
  Fund? _activeFund;
  LedgerController? _ledger;
  bool _isLoading = true;
  String? _error;

  List<Fund> get funds => _funds;
  Fund? get activeFund => _activeFund;
  LedgerController? get ledger => _ledger;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads the funds the current user can access and selects the first.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _funds = await _fundRepository.getFunds();
      if (_funds.isEmpty) {
        _setActive(null);
      } else {
        _setActive(_funds.first);
        await _ledger!.load();
      }
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
    _setActive(fund);
    notifyListeners();
    await _ledger!.load();
    return fund;
  }

  /// Switches the active fund and reloads its entries.
  Future<void> selectFund(Fund fund) async {
    if (fund.id == _activeFund?.id) {
      return;
    }

    _setActive(fund);
    notifyListeners();
    await _ledger!.load();
  }

  void _setActive(Fund? fund) {
    _activeFund = fund;
    _ledger?.dispose();
    _ledger = fund == null
        ? null
        : LedgerController(
            _entryRepository,
            fundId: fund.id,
            currency: fund.defaultCurrency,
          );
  }

  @override
  void dispose() {
    _ledger?.dispose();
    super.dispose();
  }
}
