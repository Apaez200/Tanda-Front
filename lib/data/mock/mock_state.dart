import '../../models/transaction_model.dart';

/// Single source of truth for all mock data.
///
/// Every number displayed in the app derives from this state.
/// When a deposit is made, all related values update atomically
/// so the UI is always internally consistent.
class MockState {
  MockState._() {
    _buildInitialHistory();
  }
  static final MockState instance = MockState._();

  // ── Constants ──────────────────────────────────────────────────────────
  static const int _initialParticipants = 10;
  static const int _completedRounds = 6; // rounds fully paid
  static const int _currentRound = 7;
  static const double _paymentPerRound = 1000.0; // per person per round
  static const double _cetesRetentionRate = 0.10; // 10%
  static const double _annualYieldRate = 0.09; // 9% annual CETES
  static const double _initialWalletBalance = 100000.0;

  // ── Wallet ─────────────────────────────────────────────────────────────
  double walletBalance = _initialWalletBalance;

  // ── Pool (derived from transaction history) ────────────────────────────
  /// Total deposited across all participants and rounds.
  double get totalDeposited {
    double sum = 0;
    for (final t in _transactions) {
      if (t.type == 'deposit') sum += t.amount.abs();
    }
    return sum;
  }

  /// Total CETES retained from all payments.
  double get totalCetesRetained {
    double sum = 0;
    for (final t in _transactions) {
      if (t.type == 'cetes_retention') sum += t.amount.abs();
    }
    return sum;
  }

  /// Amount flowing to pool (deposits minus CETES retention).
  double get poolInvested => totalDeposited - totalCetesRetained;

  /// Accumulated yield from CETES investment.
  double get accumulatedYield {
    double sum = 0;
    for (final t in _transactions) {
      if (t.type == 'yield') sum += t.amount;
    }
    return sum;
  }

  /// The total value of the pool: invested + yield.
  double get poolTotal => poolInvested + accumulatedYield;

  /// User's total paid across all rounds.
  double get userTotalPaid {
    double sum = 0;
    for (final t in _transactions) {
      if (t.type == 'deposit' && t.description.contains('(Tú)')) {
        sum += t.amount.abs();
      }
    }
    return sum;
  }

  /// User's accumulated CETES retention.
  double get userCetesRetained {
    double sum = 0;
    for (final t in _transactions) {
      if (t.type == 'cetes_retention' && t.description.contains('(Tú)')) {
        sum += t.amount.abs();
      }
    }
    return sum;
  }

  /// Number of rounds the user has paid.
  int get userRoundsPaid {
    int count = 0;
    for (final t in _transactions) {
      if (t.type == 'deposit' && t.description.contains('(Tú)')) count++;
    }
    return count;
  }

  /// Whether the user deposited in the current round.
  bool userPaidCurrentRound = false;

  /// Payments received this round.
  int get paymentsThisRound {
    int count = 0;
    for (final t in _transactions) {
      if (t.type == 'deposit' && t.description.contains('ronda $_currentRound')) {
        count++;
      }
    }
    return count;
  }

  // ── Transactions (the single source of truth) ──────────────────────────
  final List<Transaction> _transactions = [];

  /// All transactions, newest first. This is what the history screen shows.
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  /// Only user-visible transactions (deposits, yields, claims, collateral).
  List<Transaction> get userTransactions {
    return _transactions
        .where((t) =>
            t.type == 'deposit' && t.description.contains('(Tú)') ||
            t.type == 'yield' ||
            t.type == 'claim' ||
            t.type == 'frozen')
        .toList();
  }

  // ── Stroops conversion (for repository compatibility) ──────────────────
  int get poolInvestedStroops => (poolInvested * 1000000000).round();
  int get accumulatedYieldStroops => (accumulatedYield * 1000000000).round();
  int get totalCetesStroops => (totalCetesRetained * 1000000000).round();
  int get userTotalPaidStroops => (userTotalPaid * 1000000000).round();
  int get userCollateralStroops => (userCetesRetained * 1000000000).round();
  int get walletBalanceStroops => (walletBalance * 1000000000).round();
  int get collateralPoolStroops => (totalCetesRetained * 1000000000).round();

  // ── Actions ────────────────────────────────────────────────────────────

  /// Records a deposit made by the user. Updates wallet, pool, and history.
  void recordDeposit(double amount) {
    final now = DateTime.now();
    final dateStr = _fmtDate(now);

    // 1. Deduct from wallet
    walletBalance -= amount;
    if (walletBalance < 0) walletBalance = 0;

    // 2. Record the deposit
    _transactions.insert(0, Transaction(
      type: 'deposit',
      amount: -amount,
      date: dateStr,
      description: 'Depósito ronda $_currentRound (Tú)',
    ));

    // 3. Record CETES retention (10% of deposit)
    final retention = amount * _cetesRetentionRate;
    _transactions.insert(0, Transaction(
      type: 'cetes_retention',
      amount: -retention,
      date: dateStr,
      description: 'Retención CETES (Tú)',
    ));

    // 4. Calculate and record yield generated by this deposit
    // Yield = invested portion * daily rate * ~15 days average
    final invested = amount - retention;
    final yieldGenerated = invested > 0
        ? invested * (_annualYieldRate / 365) * 15
        : 0.0;
    if (yieldGenerated > 0.01) {
      _transactions.insert(0, Transaction(
        type: 'yield',
        amount: double.parse(yieldGenerated.toStringAsFixed(2)),
        date: dateStr,
        description: 'Rendimiento CETES generado',
      ));
    }

    userPaidCurrentRound = true;
  }

  /// Records a claim payout.
  void recordClaim(double amount) {
    walletBalance += amount;
    _transactions.insert(0, Transaction(
      type: 'claim',
      amount: amount,
      date: _fmtDate(DateTime.now()),
      description: 'Cobro de turno',
    ));
  }

  /// Amount to pass through makePayment.
  double lastDepositAmount = 1000.0;

  // ── Private helpers ────────────────────────────────────────────────────

  String _fmtDate(DateTime d) {
    final months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  /// Build 6 completed rounds of realistic history for 10 participants.
  void _buildInitialHistory() {
    final baseDate = DateTime(2025, 9, 1);

    for (int round = 1; round <= _completedRounds; round++) {
      final roundDate = DateTime(
        baseDate.year,
        baseDate.month + round - 1,
        15,
      );
      final dateStr = _fmtDate(roundDate);

      // Each of 10 participants deposits $1,000 per round
      for (int p = 0; p < _initialParticipants; p++) {
        final names = [
          'Ana L.', 'Carlos M.', 'Mariana P.', 'Fernando R.', 'Tú',
          'Laura V.', 'Sofía R.', 'Roberto S.', 'Diana M.', 'Miguel A.',
        ];
        final name = names[p];
        final isMissed = (name == 'Diana M.' && round == 6); // Diana missed round 6

        if (!isMissed) {
          _transactions.add(Transaction(
            type: 'deposit',
            amount: -_paymentPerRound,
            date: dateStr,
            description: 'Depósito ronda $round ($name)',
          ));

          _transactions.add(Transaction(
            type: 'cetes_retention',
            amount: -(_paymentPerRound * _cetesRetentionRate),
            date: dateStr,
            description: 'Retención CETES 10% ($name)',
          ));
        }
      }

      // Yield generated at end of each round
      // Cumulative: round 1 has less invested, round 6 has more
      final cumulativeInvested = round * _initialParticipants * (_paymentPerRound * (1 - _cetesRetentionRate));
      final monthlyYield = cumulativeInvested * (_annualYieldRate / 12);
      final endOfRound = DateTime(roundDate.year, roundDate.month + 1, 1);

      _transactions.add(Transaction(
        type: 'yield',
        amount: double.parse(monthlyYield.toStringAsFixed(2)),
        date: _fmtDate(endOfRound),
        description: 'Rendimiento CETES ronda $round',
      ));
    }

    // 8 of 10 already deposited in current round (round 7)
    final currentRoundDate = DateTime(2026, 3, 10);
    final currentDateStr = _fmtDate(currentRoundDate);
    final paidNames = [
      'Ana L.', 'Carlos M.', 'Mariana P.', 'Fernando R.',
      'Laura V.', 'Sofía R.', 'Roberto S.', 'Miguel A.',
    ];
    for (final name in paidNames) {
      _transactions.add(Transaction(
        type: 'deposit',
        amount: -_paymentPerRound,
        date: currentDateStr,
        description: 'Depósito ronda $_currentRound ($name)',
      ));
      _transactions.add(Transaction(
        type: 'cetes_retention',
        amount: -(_paymentPerRound * _cetesRetentionRate),
        date: currentDateStr,
        description: 'Retención CETES 10% ($name)',
      ));
    }

    // Sort newest first
    _transactions.sort((a, b) {
      // Approximate sort by round number in description
      final aRound = _extractRound(a.description);
      final bRound = _extractRound(b.description);
      return bRound.compareTo(aRound);
    });

    // Deduct user's 6 rounds from wallet
    walletBalance = _initialWalletBalance - (_completedRounds * _paymentPerRound);
    if (walletBalance < 0) walletBalance = 0;
  }

  int _extractRound(String desc) {
    final match = RegExp(r'ronda (\d+)').firstMatch(desc);
    return match != null ? int.parse(match.group(1)!) : 0;
  }
}
