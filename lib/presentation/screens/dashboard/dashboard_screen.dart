import 'dart:async';
import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/prototype_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_data.dart';
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
  bool _userDeposited = false;

  final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _userDeposited = userDepositedNotifier.value;
    userDepositedNotifier.addListener(_onDepositChange);
  }

  void _onDepositChange() {
    if (mounted) setState(() => _userDeposited = userDepositedNotifier.value);
  }

  @override
  void dispose() {
    userDepositedNotifier.removeListener(_onDepositChange);
    super.dispose();
  }

  DateTime get _cutoff {
    final now = DateTime.now();
    return DateTime(now.year, now.month, mockTanda.cutoffDay, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHome(),
      const _DepositTab(),
      const _HistoryTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: Text('TandaChain', style: titleBold(22, color: accentGold)),
        actions: [
          // Prototype: simulate turno
          Tooltip(
            message: 'Simular mi turno (prototipo)',
            child: IconButton(
              icon: const Icon(Icons.emoji_events_rounded, color: accentGold),
              onPressed: () => context.push('/claim'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: offWhite),
            onPressed: () {},
          ),
        ],
      ),
      body: tabs[_tab],
      bottomNavigationBar: NavigationBar(
        backgroundColor: cardBg,
        indicatorColor: primaryGreen.withOpacity(0.35),
        selectedIndex: _tab == 0 ? 0 : (_tab == 3 ? 3 : 0),
        onDestinationSelected: (i) {
          if (i == 1) {
            context.push('/deposit');
          } else if (i == 2) {
            context.push('/history');
          } else {
            setState(() => _tab = i == 3 ? 3 : 0);
          }
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          const NavigationDestination(
            icon: Icon(Icons.payments_rounded),
            label: 'Depositar',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Historial'),
          const NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final tanda = mockTanda;
    final deposited = mockParticipants.where((p) => p.hasDeposited || (p.isMe && _userDeposited)).length;

    return CustomScrollView(
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
                  child: _MainPoolCard(tanda: tanda, fmt: _fmt),
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
                        participants: mockParticipants,
                        userHasDeposited: _userDeposited,
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
                    deposited: _userDeposited,
                    onDeposit: () => context.push('/deposit'),
                    fmt: _fmt,
                    amount: tanda.amountPerPerson,
                  ),
                ),
                const SizedBox(height: 16),

                // EXIT LINK
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.exit_to_app, size: 16, color: softGray),
                    label: Text('Salir de la tanda', style: bodyText(13, color: softGray)),
                    onPressed: () => context.push('/exit'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── CARD PRINCIPAL ───────────────────────────────────────────────────────────

class _MainPoolCard extends StatelessWidget {
  const _MainPoolCard({required this.tanda, required this.fmt});
  final dynamic tanda;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final total = tanda.poolTotal + tanda.accumulatedYield;
    // tiny increment per tick
    final tickIncrement = tanda.poolTotal * mockDailyNetAPY / 8640;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGold.withOpacity(0.6), width: 1.5),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryGreen.withOpacity(0.5)),
                ),
                child: Text('Activa', style: bodyText(12, color: successGreen, weight: FontWeight.w600)),
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
              const Icon(Icons.trending_up_rounded, color: successGreen, size: 18),
              const SizedBox(width: 4),
              Text(
                '+${fmt.format(tanda.accumulatedYield)} generados este mes ✨',
                style: bodyText(13, color: successGreen, weight: FontWeight.w600),
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
    required this.onDeposit,
    required this.fmt,
    required this.amount,
  });
  final bool deposited;
  final VoidCallback onDeposit;
  final NumberFormat fmt;
  final double amount;

  @override
  Widget build(BuildContext context) {
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
            const Icon(Icons.check_circle_rounded, color: successGreen, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Depositado', style: titleSemi(15, color: successGreen)),
                  Text(
                    'Llevas 15 días generando rendimiento',
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
          Text('Tu turno es el 3 — aún no has depositado', style: bodyText(14, color: softGray)),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Depositar ${fmt.format(amount)} ahora →',
            onPressed: onDeposit,
            variant: CustomButtonVariant.primary,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

// ─── TABS PLACEHOLDER ──────────────────────────────────────────────────────────

class _DepositTab extends StatelessWidget {
  const _DepositTab();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => context.push('/deposit'));
    return const SizedBox.shrink();
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => context.push('/history'));
    return const SizedBox.shrink();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.person_rounded, color: offWhite, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Tú', style: titleBold(22)),
          const SizedBox(height: 4),
          Text('Turno #3 • Miembro activo', style: bodyText(14, color: softGray)),
          const SizedBox(height: 24),
          _statRow('Tandas completadas', '1'),
          _statRow('Rendimiento total', '+\$192.50 MXN'),
          _statRow('Participación', 'Turno 3 de 5'),
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
            Text(val, style: bodyText(14, color: accentGold, weight: FontWeight.w600)),
          ],
        ),
      );
}
