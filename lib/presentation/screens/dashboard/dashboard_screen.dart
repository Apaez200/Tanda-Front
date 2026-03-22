import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/contract_constants.dart';
import '../../../core/prototype_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../injection.dart';
import '../../../models/participant_model.dart';
import '../../../models/tanda_model.dart';
import '../../../models/tanda_config_model.dart';
import '../../../models/investment_pool_model.dart';
import '../../../models/round_info_model.dart';
import '../../../models/participant_info_model.dart';
import '../../../models/tanda_error_model.dart';
import '../../widgets/countdown_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/participant_ring_widget.dart';
import '../../widgets/yield_counter_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardView();
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _tab = 0;

  final _fmt =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

  // Data from blockchain
  Tanda? _tanda;
  List<Participant> _participants = [];
  RoundInfo? _roundInfo;
  TandaConfig? _config;
  InvestmentPool _pool = const InvestmentPool(
    totalCetesTokens: 0,
    totalUsdcInvested: 0,
    accumulatedYield: 0,
  );
  ParticipantInfo? _myInfo;
  bool _isLoading = true;
  String? _error;

  String? _myAddress;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _myAddress = await walletRepository.getConnectedPublicKey();

      final config = await tandaRepository.getConfig();

      // Fetch data in parallel using named futures (avoids fragile index math)
      InvestmentPool pool = const InvestmentPool(
        totalCetesTokens: 0,
        totalUsdcInvested: 0,
        accumulatedYield: 0,
      );
      RoundInfo? roundInfo;
      List<ParticipantInfo> allParticipants = [];

      try {
        final poolFuture = tandaRepository.getCollateralPool();
        final roundFuture = config.status != TandaStatus.registering
            ? tandaRepository.getRoundInfo()
            : Future<RoundInfo?>.value(null);
        final participantsFuture = tandaRepository.getAllParticipants();

        final results = await Future.wait([poolFuture, roundFuture, participantsFuture]);

        pool = results[0] as InvestmentPool;
        roundInfo = results[1] as RoundInfo?;
        allParticipants = results[2] as List<ParticipantInfo>;
      } catch (e) {
        // Gracefully handle — pool/round may not exist yet
        debugPrint('[Dashboard] Error loading pool/round/participants: $e');
        try {
          allParticipants = await tandaRepository.getAllParticipants();
        } catch (_) {}
      }

      // Find my info
      ParticipantInfo? myInfo;
      int myTurn = 0;
      for (final p in allParticipants) {
        if (p.address == _myAddress) {
          myInfo = p;
          myTurn = p.turn + 1;
          break;
        }
      }

      // Convert to UI models
      final participants = allParticipants
          .map((p) => Participant.fromContract(
                p,
                myAddress: _myAddress ?? '',
                currentRound: config.currentRound,
              ))
          .toList();

      final activeContractId = await tandaStorage.getActiveTandaId()
          ?? ContractConstants.tandaContractId;
      final tanda = Tanda.fromContract(
        config: config,
        pool: pool,
        myTurn: myTurn,
        contractId: activeContractId,
      );

      if (mounted) {
        setState(() {
          _config = config;
          _pool = pool;
          _roundInfo = roundInfo; // may be null in Registering state
          _myInfo = myInfo;
          _tanda = tanda;
          _participants = participants;
          _isLoading = false;

          // Update deposit status from blockchain
          if (myInfo != null) {
            userDepositedNotifier.value =
                !myInfo.hasNeverPaid && myInfo.lastPaidRound >= config.currentRound;
          }
        });
      }
    } on TandaException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.error.userMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error cargando datos: $e';
        });
      }
    }
  }

  DateTime get _cutoff {
    if (_roundInfo != null) {
      return _roundInfo!.endDate;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, 30, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHome(),
      _buildProfile(),
    ];

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: offWhite),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/hub');
            }
          },
        ),
        title: Text('Rendix', style: titleBold(22, color: accentGold)),
        actions: [
          if (_config?.status == TandaStatus.active && _roundInfo != null)
            Tooltip(
              message: 'Cobrar turno',
              child: IconButton(
                icon: const Icon(Icons.emoji_events_rounded, color: accentGold),
                onPressed: () => context.push('/claim'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: offWhite),
            onPressed: _loadData,
          ),
          IconButton(
            icon:
                const Icon(Icons.account_balance_wallet_outlined, color: offWhite),
            onPressed: () {
              if (_myAddress != null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: cardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text('Mi Wallet', style: titleBold(18)),
                    content: SelectableText(
                      _myAddress!,
                      style: bodyText(12, color: offWhite),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cerrar', style: bodyText(14, color: softGray)),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: tabs[_tab == 3 ? 1 : 0],
      bottomNavigationBar: NavigationBar(
        backgroundColor: cardBg,
        indicatorColor: primaryGreen.withOpacity(0.35),
        selectedIndex: _tab,
        onDestinationSelected: (i) async {
          if (i == 1) {
            await context.push('/deposit');
            _loadData(); // Refresh after deposit
          } else if (i == 2) {
            context.push('/history');
          } else {
            setState(() => _tab = i);
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.payments_rounded), label: 'Depositar'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded), label: 'Historial'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentGold),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: warningRed, size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: bodyText(14, color: softGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Reintentar',
                onPressed: _loadData,
                variant: CustomButtonVariant.secondary,
              ),
            ],
          ),
        ),
      );
    }

    final tanda = _tanda!;
    final deposited =
        _participants.where((p) => p.hasDeposited).length;
    final userDeposited = userDepositedNotifier.value;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: accentGold,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD PRINCIPAL
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: _MainPoolCard(
                        tanda: tanda, fmt: _fmt, pool: _pool),
                  ),
                  const SizedBox(height: 20),

                  // STATUS BADGE
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    child: _StatusBadge(status: _config!.status),
                  ),
                  const SizedBox(height: 20),

                  // COUNTDOWN
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Próximo corte', style: titleSemi(16)),
                        const SizedBox(height: 12),
                        CountdownWidget(
                          targetDateTime: _cutoff,
                          numberColor: accentGold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PARTICIPANTES
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Participantes ($deposited/${tanda.totalParticipants} depositaron)',
                          style: titleSemi(16),
                        ),
                        const SizedBox(height: 14),
                        ParticipantRingWidget(
                          participants: _participants,
                          userHasDeposited: userDeposited,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ESTADO DEL USUARIO
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 300),
                    child: _UserStatusCard(
                      deposited: userDeposited,
                      registered: _myInfo != null,
                      onDeposit: () async {
                        await context.push('/deposit');
                        _loadData();
                      },
                      onRegister: _registerInTanda,
                      fmt: _fmt,
                      amount: tanda.amountPerPerson,
                      status: _config!.status,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // EXIT LINK
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.exit_to_app,
                          size: 16, color: softGray),
                      label: Text('Salir del grupo',
                          style: bodyText(13, color: softGray)),
                      onPressed: () => context.push('/exit'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerInTanda() async {
    final secretKey = await walletRepository.getSavedSecretKey();
    if (secretKey == null || secretKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cardBg,
            content: Text('Conecta tu wallet primero',
                style: bodyText(13, color: warningRed)),
          ),
        );
      }
      return;
    }

    try {
      await tandaRepository.register(signerSecretKey: secretKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cardBg,
            content: Text('Registrado exitosamente',
                style: bodyText(13, color: successGreen)),
          ),
        );
        _loadData(); // Refresh
      }
    } on TandaException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cardBg,
            content:
                Text(e.error.userMessage, style: bodyText(13, color: warningRed)),
          ),
        );
      }
    }
  }

  Widget _buildProfile() {
    final myTurn = _myInfo?.turn ?? 0;
    final totalPaid = _myInfo?.totalPaidMXN ?? 0;
    final collateral = _myInfo?.collateralHeldMXN ?? 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryGreen.withOpacity(0.3),
              border: Border.all(color: accentGold, width: 2),
            ),
            child:
                const Icon(Icons.person_rounded, color: offWhite, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Tú', style: titleBold(22)),
          const SizedBox(height: 4),
          Text(
            'Turno #${myTurn + 1} • ${_config?.status == TandaStatus.active ? "Miembro activo" : "Registrado"}',
            style: bodyText(14, color: softGray),
          ),
          if (_myAddress != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_myAddress!.substring(0, 8)}...${_myAddress!.substring(_myAddress!.length - 8)}',
              style: bodyText(11, color: softGray),
            ),
          ],
          const SizedBox(height: 24),
          _statRow('Total pagado', _fmt.format(totalPaid)),
          _statRow('Colateral retenido', _fmt.format(collateral)),
          _statRow('Turno', '${myTurn + 1} de ${_config?.maxParticipants ?? 5}'),
          _statRow('Rendimiento pool', _fmt.format(_pool.accumulatedYieldMXN)),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: CustomButton(
              label: 'Desconectar wallet',
              onPressed: () async {
                await walletRepository.clearKeypair();
                walletPublicKeyNotifier.value = null;
                if (mounted) context.go('/login');
              },
              variant: CustomButtonVariant.danger,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String val) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: bodyText(14, color: softGray)),
            Text(val,
                style:
                    bodyText(14, color: accentGold, weight: FontWeight.w600)),
          ],
        ),
      );
}

// ─── STATUS BADGE ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TandaStatus status;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    switch (status) {
      case TandaStatus.registering:
        label = 'Registrando';
        color = accentGold;
      case TandaStatus.active:
        label = 'Activa';
        color = successGreen;
      case TandaStatus.completed:
        label = 'Completada';
        color = softGray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: bodyText(12, color: color, weight: FontWeight.w600)),
    );
  }
}

// ─── CARD PRINCIPAL ───────────────────────────────────────────────────────────

class _MainPoolCard extends StatelessWidget {
  const _MainPoolCard({
    required this.tanda,
    required this.fmt,
    required this.pool,
  });
  final Tanda tanda;
  final NumberFormat fmt;
  final InvestmentPool pool;

  @override
  Widget build(BuildContext context) {
    final total = tanda.poolTotal + tanda.accumulatedYield;
    // Approximate daily yield rate based on pool data
    final dailyRate = pool.yieldPercentage > 0 ? pool.yieldPercentage / 100 / 365 : 0.000246;
    final tickIncrement = total * dailyRate / 8640;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: accentGold.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentGold.withOpacity(0.2),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tanda.name, style: titleSemi(17)),
                    Text(
                      'Ronda ${tanda.currentRound} de ${tanda.totalParticipants}',
                      style: bodyText(13, color: softGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('La Caja', style: bodyText(13, color: softGray)),
          const SizedBox(height: 4),
          YieldCounterWidget(
            initialValue: total,
            incrementPerTick: tickIncrement,
            tickSeconds: 10,
            format: (v) => fmt.format(v),
            textStyle: titleBold(38, color: offWhite),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: successGreen, size: 18),
              const SizedBox(width: 4),
              Text(
                '+${fmt.format(tanda.accumulatedYield)} generados',
                style: bodyText(13,
                    color: successGreen, weight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ESTADO USUARIO ────────────────────────────────────────────────────────────

class _UserStatusCard extends StatelessWidget {
  const _UserStatusCard({
    required this.deposited,
    required this.registered,
    required this.onDeposit,
    required this.onRegister,
    required this.fmt,
    required this.amount,
    required this.status,
  });
  final bool deposited;
  final bool registered;
  final VoidCallback onDeposit;
  final VoidCallback onRegister;
  final NumberFormat fmt;
  final double amount;
  final TandaStatus status;

  @override
  Widget build(BuildContext context) {
    // Not registered yet
    if (!registered && status == TandaStatus.registering) {
      final initialPayment = amount * 0.10;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentGold.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aún no estás registrado en este grupo',
                style: bodyText(14, color: softGray)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentGold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: accentGold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pago inicial: ${fmt.format(initialPayment)} (10% del primer pago)',
                      style: bodyText(12, color: accentGold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Registrarme (${fmt.format(initialPayment)})',
              onPressed: onRegister,
              variant: CustomButtonVariant.primary,
              fullWidth: true,
            ),
          ],
        ),
      );
    }

    if (deposited) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: successGreen.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: successGreen, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Depositado',
                      style: titleSemi(15, color: successGreen)),
                  Text(
                    'Tu pago de esta ronda fue registrado',
                    style: bodyText(13, color: softGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentGold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aún no has depositado esta ronda',
              style: bodyText(14, color: softGray)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentGold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_rounded, color: accentGold, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '10% de tu depósito se invierte en CETES',
                    style: bodyText(11, color: accentGold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Depositar ahora',
            onPressed: onDeposit,
            variant: CustomButtonVariant.primary,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

