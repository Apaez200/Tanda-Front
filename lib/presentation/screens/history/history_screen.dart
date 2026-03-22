import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/contract_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_state.dart';
import '../../../injection.dart';
import '../../../models/investment_pool_model.dart';
import '../../../models/participant_info_model.dart';
import '../../../models/tanda_error_model.dart';
import '../../../models/transaction_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Transaction> _transactions = [];
  double _totalYield = 0;
  int _roundsParticipated = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      if (ContractConstants.useMock) {
        // Read directly from the single source of truth
        final s = MockState.instance;
        if (mounted) {
          setState(() {
            _transactions = s.userTransactions;
            _totalYield = s.accumulatedYield;
            _roundsParticipated = s.userRoundsPaid;
            _isLoading = false;
          });
        }
        return;
      }

      // Real blockchain path
      final myAddress = await walletRepository.getConnectedPublicKey();
      if (myAddress == null) {
        setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        tandaRepository.getParticipant(myAddress),
        tandaRepository.getCollateralPool(),
        tandaRepository.getConfig(),
      ]);

      final participant = results[0] as ParticipantInfo;
      final pool = results[1] as InvestmentPool;

      final transactions = <Transaction>[];

      if (participant.totalPaid > 0) {
        transactions.add(Transaction(
          type: 'deposit',
          amount: -participant.totalPaidMXN,
          date: 'Ronda ${participant.lastPaidRound}',
          description: 'Depósito de ronda',
        ));
      }

      if (pool.accumulatedYield > 0) {
        transactions.add(Transaction(
          type: 'yield',
          amount: pool.accumulatedYieldMXN,
          date: 'Acumulado',
          description: 'Rendimiento acumulado CETES',
        ));
      }

      if (participant.hasReceivedPayout) {
        transactions.add(Transaction(
          type: 'claim',
          amount: participant.totalPaidMXN + pool.accumulatedYieldMXN,
          date: 'Turno ${participant.turn + 1}',
          description: 'Cobro de turno',
        ));
      }

      if (participant.collateralHeld > 0) {
        transactions.add(Transaction(
          type: 'frozen',
          amount: -participant.collateralHeldMXN,
          date: 'Activo',
          description: 'Colateral retenido',
        ));
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _totalYield = pool.accumulatedYieldMXN;
          _roundsParticipated =
              participant.hasNeverPaid ? 0 : participant.lastPaidRound + 1;
          _isLoading = false;
        });
      }
    } on TandaException catch (e) {
      debugPrint('[History] TandaException: ${e.error.userMessage}');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A1A1A),
            content: Text(e.error.userMessage,
                style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13)),
          ),
        );
      }
    } catch (e) {
      debugPrint('[History] Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text('Mi Historial', style: titleBold(20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: accentGold))
          : CustomScrollView(
              slivers: [
                // RESUMEN
                SliverToBoxAdapter(
                  child: FadeInDown(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: successGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Total rendimientos',
                                      style: bodyText(13,
                                          color: softGray)),
                                  Text(
                                    '+\$${_totalYield.toStringAsFixed(2)} MXN',
                                    style: titleBold(22,
                                        color: successGreen),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text('Rondas pagadas',
                                    style: bodyText(12,
                                        color: softGray)),
                                Text('$_roundsParticipated',
                                    style: titleBold(22,
                                        color: accentGold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child:
                        Text('Transacciones', style: titleSemi(16)),
                  ),
                ),

                // LISTA
                if (_transactions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No hay transacciones aún',
                          style: bodyText(14, color: softGray),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.separated(
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemCount: _transactions.length,
                      itemBuilder: (ctx, i) {
                        final t = _transactions[i];
                        return FadeInUp(
                          delay: Duration(milliseconds: i * 60),
                          child: _TransactionTile(transaction: t),
                        );
                      },
                    ),
                  ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: 24)),
              ],
            ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final info = _typeInfo(transaction.type);
    final positive = transaction.amount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: info.color.withOpacity(0.15),
            ),
            child: Icon(info.icon, color: info.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description,
                    style: bodyText(14, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(transaction.date,
                    style: bodyText(12, color: softGray)),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}\$${transaction.amount.abs().toStringAsFixed(2)}',
            style: titleSemi(15,
                color: positive ? successGreen : warningRed),
          ),
        ],
      ),
    );
  }

  _TxInfo _typeInfo(String type) {
    switch (type) {
      case 'yield':
        return _TxInfo(Icons.trending_up_rounded, successGreen);
      case 'claim':
        return _TxInfo(Icons.emoji_events_rounded, accentGold);
      case 'frozen':
        return _TxInfo(Icons.lock_rounded, Colors.lightBlue);
      case 'cetes_retention':
        return _TxInfo(Icons.account_balance_rounded, accentGold);
      default:
        return _TxInfo(Icons.payments_rounded, warningRed);
    }
  }
}

class _TxInfo {
  const _TxInfo(this.icon, this.color);
  final IconData icon;
  final Color color;
}
