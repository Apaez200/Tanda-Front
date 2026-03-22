import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/prototype_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/tanda_storage_service.dart';
import '../../../injection.dart';
import '../../../models/tanda_config_model.dart';

const _bg = Color(0xFF060608);
const _cardColor = Color(0xFF0E0F14);
const _borderColor = Color(0xFF1E1F2A);
const _mint = Color(0xFF0CFFC5);
const _purple = Color(0xFF6C63FF);

class TandaHubScreen extends StatefulWidget {
  const TandaHubScreen({super.key});

  @override
  State<TandaHubScreen> createState() => _TandaHubScreenState();
}

class _TandaHubScreenState extends State<TandaHubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  final _fmt =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

  String? _address;
  int _usdcBalance = 0;
  List<_TandaPreview> _activeTandas = [];
  List<_TandaPreview> _completedTandas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadAll();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    final addr = await walletRepository.getConnectedPublicKey();
    int balance = 0;
    if (addr != null) {
      balance = await walletRepository.getUsdcBalance(addr);
    }

    final saved = await tandaStorage.getSavedTandas();
    final active = <_TandaPreview>[];
    final completed = <_TandaPreview>[];

    for (final s in saved) {
      TandaConfig? config;
      int participants = 0;
      try {
        setActiveTandaContract(s.contractId);
        config = await tandaRepository.getConfig();
        try {
          final all = await tandaRepository.getAllParticipants();
          participants = all.length;
        } catch (e) {
          debugPrint('[Hub] Error loading participants for ${s.contractId}: $e');
        }
      } catch (e) {
        debugPrint('[Hub] Error loading config for ${s.contractId}: $e');
      }

      final preview = _TandaPreview(
        saved: s,
        config: config,
        participantCount: participants,
      );

      if (config?.status == TandaStatus.completed) {
        completed.add(preview);
      } else {
        active.add(preview);
      }
    }

    if (mounted) {
      setState(() {
        _address = addr;
        _usdcBalance = balance;
        _activeTandas = active;
        _completedTandas = completed;
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: warningRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: warningRed, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Cerrar sesion', style: titleSemi(18, color: offWhite)),
            const SizedBox(height: 8),
            Text(
              'Se desconectara tu wallet de este dispositivo.',
              style: bodyText(13, color: const Color(0xFF6B6D7B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Center(
                        child: Text('Cancelar',
                            style: bodyText(14, color: softGray)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: warningRed.withValues(alpha: 0.15),
                        border: Border.all(
                            color: warningRed.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text('Cerrar sesion',
                            style: bodyText(14,
                                color: warningRed,
                                weight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      await walletRepository.clearKeypair();
      walletPublicKeyNotifier.value = null;
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final short = _address != null
        ? '${_address!.substring(0, 6)}...${_address!.substring(_address!.length - 4)}'
        : '';
    final balanceMXN = _usdcBalance / 1000000;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Glow orb
          Positioned(
            top: -120,
            right: -80,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) => Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    accentGold.withValues(
                        alpha: 0.06 * _glowController.value),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              color: _mint,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── TOP BAR ──
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [accentGold, Color(0xFFB8892E)],
                              ),
                            ),
                            child: const Icon(Icons.link_rounded,
                                color: _bg, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TandaChain',
                                  style: titleBold(20, color: offWhite)),
                              Text('Stellar Testnet',
                                  style: bodyText(11,
                                      color: _mint,
                                      weight: FontWeight.w500)),
                            ],
                          ),
                          const Spacer(),
                          if (_address != null)
                            GestureDetector(
                              onTap: () => _showAccountSheet(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _borderColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: _mint,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(short,
                                        style: bodyText(11,
                                            color: softGray,
                                            weight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          // Logout button visible in top bar
                          GestureDetector(
                            onTap: _logout,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _borderColor),
                              ),
                              child: const Icon(Icons.logout_rounded,
                                  color: Color(0xFF6B6D7B), size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── BALANCE CARD ──
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: GestureDetector(
                        onTap: () {
                          context.push('/portfolio', extra: {
                            'balance': balanceMXN,
                            'activeTandas': _activeTandas.length,
                            'completedTandas': _completedTandas.length,
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF141520),
                                Color(0xFF0E0F14),
                              ],
                            ),
                            border: Border.all(
                                color: accentGold.withValues(alpha: 0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: accentGold.withValues(alpha: 0.06),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Mi dinero disponible',
                                      style: bodyText(13,
                                          color: const Color(0xFF6B6D7B))),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFF4A4B55), size: 14),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _isLoading
                                  ? const SizedBox(
                                      height: 42,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: accentGold),
                                      ),
                                    )
                                  : Text(
                                      _fmt.format(balanceMXN),
                                      style: titleBold(36, color: offWhite),
                                    ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('USDC en tu cuenta',
                                      style: bodyText(12,
                                          color: const Color(0xFF4A4B55))),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _mint.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.trending_up_rounded,
                                            color: _mint,
                                            size: 12),
                                        const SizedBox(width: 3),
                                        Text('~9% anual',
                                            style: bodyText(10,
                                                color: _mint,
                                                weight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── QUICK ACTIONS (right after balance) ──
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'Depositar',
                              color: _mint,
                              onTap: () {
                                if (_activeTandas.isEmpty) {
                                  _showSnack(
                                      'Primero crea o unete a una tanda');
                                } else if (_activeTandas.length == 1) {
                                  setActiveTandaContract(
                                      _activeTandas.first.saved.contractId);
                                  context.push('/deposit');
                                } else {
                                  _showSelectTandaForDeposit(context);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.add_rounded,
                              label: 'Crear',
                              color: accentGold,
                              onTap: () async {
                                await context.push('/create-tanda');
                                _loadAll();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.group_add_rounded,
                              label: 'Unirme',
                              color: _purple,
                              onTap: () async {
                                await context.push('/join-tanda');
                                _loadAll();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── MIS TANDAS ──
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Row(
                        children: [
                          Text('Mis tandas',
                              style: titleSemi(18, color: offWhite)),
                          const Spacer(),
                          if (_activeTandas.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _mint.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  '${_activeTandas.length} activa${_activeTandas.length == 1 ? '' : 's'}',
                                  style: bodyText(11,
                                      color: _mint,
                                      weight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _mint),
                        ),
                      )
                    else if (_activeTandas.isEmpty)
                      _EmptyTandas()
                    else
                      ...List.generate(_activeTandas.length, (i) {
                        final t = _activeTandas[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: Duration(milliseconds: 250 + i * 80),
                            child: _TandaListItem(
                              preview: t,
                              onTap: () {
                                setActiveTandaContract(
                                    t.saved.contractId);
                                context.push('/dashboard');
                              },
                            ),
                          ),
                        );
                      }),

                    // ── TANDAS FINALIZADAS ──
                    if (_completedTandas.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: Row(
                          children: [
                            Text('Finalizadas',
                                style: titleSemi(16, color: softGray)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: softGray.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${_completedTandas.length}',
                                  style: bodyText(11,
                                      color: softGray,
                                      weight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(_completedTandas.length, (i) {
                        final t = _completedTandas[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TandaListItem(
                            preview: t,
                            completed: true,
                            onTap: () {
                              setActiveTandaContract(
                                  t.saved.contractId);
                              context.push('/dashboard');
                            },
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _cardColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, style: bodyText(13, color: _mint)),
      ),
    );
  }

  void _showSelectTandaForDeposit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Selecciona una tanda',
                style: titleSemi(16, color: offWhite)),
            const SizedBox(height: 16),
            ...List.generate(_activeTandas.length, (i) {
              final t = _activeTandas[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setActiveTandaContract(t.saved.contractId);
                    context.push('/deposit');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _mint.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.savings_rounded,
                              color: _mint, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(t.saved.name,
                              style: bodyText(14, color: offWhite)),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: _mint, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mint.withValues(alpha: 0.1),
                border:
                    Border.all(color: _mint.withValues(alpha: 0.3)),
              ),
              child:
                  const Icon(Icons.person_rounded, color: _mint, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Mi cuenta', style: titleSemi(18)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Direccion',
                      style: bodyText(10,
                          color: const Color(0xFF6B6D7B))),
                  const SizedBox(height: 4),
                  SelectableText(_address!,
                      style: bodyText(11, color: accentGold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Balance USDC',
                          style: bodyText(10,
                              color: const Color(0xFF6B6D7B))),
                      const SizedBox(height: 4),
                      Text(_fmt.format(_usdcBalance / 1000000),
                          style: titleSemi(16, color: _mint)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Tandas',
                          style: bodyText(10,
                              color: const Color(0xFF6B6D7B))),
                      const SizedBox(height: 4),
                      Text(
                          '${_activeTandas.length + _completedTandas.length}',
                          style: titleSemi(16, color: accentGold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Center(
                  child: Text('Cerrar',
                      style: bodyText(14, color: softGray)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS ────────────────────────────────────────────────────────────────

class _TandaPreview {
  final SavedTanda saved;
  final TandaConfig? config;
  final int participantCount;
  const _TandaPreview({
    required this.saved,
    this.config,
    this.participantCount = 0,
  });
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: bodyText(12,
                    color: color, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TandaListItem extends StatelessWidget {
  const _TandaListItem({
    required this.preview,
    required this.onTap,
    this.completed = false,
  });
  final _TandaPreview preview;
  final VoidCallback onTap;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final config = preview.config;
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    final Color statusColor;
    final String statusLabel;
    if (completed) {
      statusColor = softGray;
      statusLabel = 'Finalizada';
    } else if (config?.status == TandaStatus.registering) {
      statusColor = accentGold;
      statusLabel = 'Registrando';
    } else {
      statusColor = _mint;
      statusLabel = 'Activa';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed
                ? _borderColor
                : statusColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: statusColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                preview.saved.role == 'admin'
                    ? Icons.shield_rounded
                    : Icons.people_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(preview.saved.name,
                      style: titleSemi(14, color: offWhite)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(statusLabel,
                            style: bodyText(9,
                                color: statusColor,
                                weight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      if (config != null)
                        Text(
                          '${preview.participantCount}/${config.maxParticipants} · ${fmt.format(config.paymentAmount / 1000000)}',
                          style: bodyText(11,
                              color: const Color(0xFF6B6D7B)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: statusColor.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }
}

class _EmptyTandas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.savings_outlined,
              color: Color(0xFF3A3C48), size: 36),
          const SizedBox(height: 12),
          Text('Aun no tienes tandas',
              style: titleSemi(15, color: softGray)),
          const SizedBox(height: 4),
          Text(
            'Crea una tanda o unete a una para empezar a ahorrar en grupo.',
            style: bodyText(12, color: const Color(0xFF4A4B55)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
