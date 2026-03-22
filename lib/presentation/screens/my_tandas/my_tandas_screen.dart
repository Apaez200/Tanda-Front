import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

class MyTandasScreen extends StatefulWidget {
  const MyTandasScreen({super.key});

  @override
  State<MyTandasScreen> createState() => _MyTandasScreenState();
}

class _MyTandasScreenState extends State<MyTandasScreen> {
  List<_TandaCard> _tandas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final saved = await tandaStorage.getSavedTandas();
    final cards = <_TandaCard>[];

    for (final s in saved) {
      TandaConfig? config;
      int participants = 0;
      try {
        // Temporarily point repo at this contract to fetch config
        setActiveTandaContract(s.contractId);
        config = await tandaRepository.getConfig();
        try {
          final all = await tandaRepository.getAllParticipants();
          participants = all.length;
        } catch (_) {}
      } catch (_) {
        // Contract unreachable — show with defaults
      }

      cards.add(_TandaCard(
        saved: s,
        config: config,
        participantCount: participants,
      ));
    }

    if (mounted) {
      setState(() {
        _tandas = cards;
        _isLoading = false;
      });
    }
  }

  void _openTanda(_TandaCard card) {
    setActiveTandaContract(card.saved.contractId);
    context.go('/dashboard');
  }

  void _inviteTanda(_TandaCard card) {
    final id = card.saved.contractId;
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Contract ID copiado — compártelo para que se unan',
            style: bodyText(13, color: _mint)),
      ),
    );
  }

  void _deleteTanda(_TandaCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _borderColor),
        ),
        title: Text('Remover tanda', style: titleSemi(16)),
        content: Text(
          'Se eliminará de tu lista local. No afecta la blockchain.',
          style: bodyText(13, color: softGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: bodyText(14, color: softGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: bodyText(14, color: warningRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await tandaStorage.removeTanda(card.saved.contractId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: offWhite),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _purple,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('Mis Tandas', style: titleSemi(18, color: offWhite)),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _mint))
            : _tandas.isEmpty
                ? _buildEmpty()
                : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_rounded,
                  color: _purple, size: 36),
            ),
            const SizedBox(height: 20),
            Text('No tienes tandas aún',
                style: titleSemi(18)),
            const SizedBox(height: 8),
            Text(
              'Crea una nueva tanda o únete a una existente desde el panel principal.',
              style: bodyText(14, color: const Color(0xFF6B6D7B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SmallAction(
                  icon: Icons.add_rounded,
                  label: 'Crear',
                  color: accentGold,
                  onTap: () => context.push('/create-tanda'),
                ),
                const SizedBox(width: 16),
                _SmallAction(
                  icon: Icons.group_add_rounded,
                  label: 'Unirse',
                  color: _mint,
                  onTap: () => context.push('/join-tanda'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: _load,
      color: _mint,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _tandas.length,
        itemBuilder: (_, i) {
          final card = _tandas[i];
          final config = card.config;
          final status = config?.status ?? TandaStatus.registering;
          final spots = (config?.maxParticipants ?? 0) - card.participantCount;

          final Color statusColor;
          final String statusLabel;
          switch (status) {
            case TandaStatus.registering:
              statusColor = accentGold;
              statusLabel = 'Registrando';
            case TandaStatus.active:
              statusColor = successGreen;
              statusLabel = 'Activa';
            case TandaStatus.completed:
              statusColor = softGray;
              statusLabel = 'Completada';
          }

          return FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: Duration(milliseconds: i * 80),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderColor),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openTanda(card),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor.withValues(alpha: 0.15),
                                    statusColor.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                              child: Icon(
                                card.saved.role == 'admin'
                                    ? Icons.shield_rounded
                                    : Icons.people_rounded,
                                color: statusColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(card.saved.name,
                                      style: titleSemi(15)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: statusColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(statusLabel,
                                            style: bodyText(9,
                                                color: statusColor,
                                                weight: FontWeight.w700)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1B24),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                            card.saved.role == 'admin'
                                                ? 'Admin'
                                                : 'Miembro',
                                            style: bodyText(9,
                                                color: softGray,
                                                weight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Actions
                            _IconAction(
                              icon: Icons.share_rounded,
                              color: _mint,
                              onTap: () => _inviteTanda(card),
                              tooltip: 'Invitar',
                            ),
                            const SizedBox(width: 4),
                            _IconAction(
                              icon: Icons.delete_outline_rounded,
                              color: warningRed.withValues(alpha: 0.6),
                              onTap: () => _deleteTanda(card),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                        if (config != null) ...[
                          const SizedBox(height: 14),
                          Container(height: 1, color: _borderColor),
                          const SizedBox(height: 12),
                          // Stats row
                          Row(
                            children: [
                              _MiniStat(
                                icon: Icons.people_alt_rounded,
                                value:
                                    '${card.participantCount}/${config.maxParticipants}',
                                label: 'Miembros',
                              ),
                              const SizedBox(width: 16),
                              _MiniStat(
                                icon: Icons.paid_rounded,
                                value: fmt.format(
                                    config.paymentAmount / 1000000),
                                label: 'Por ronda',
                              ),
                              const SizedBox(width: 16),
                              if (status == TandaStatus.registering &&
                                  spots > 0)
                                _MiniStat(
                                  icon: Icons.event_seat_rounded,
                                  value: '$spots',
                                  label: 'Lugares',
                                  valueColor: _mint,
                                ),
                              if (status == TandaStatus.active)
                                _MiniStat(
                                  icon: Icons.sync_rounded,
                                  value:
                                      'R${config.currentRound}/${config.totalRounds}',
                                  label: 'Ronda',
                                ),
                            ],
                          ),
                        ],
                        // Contract ID
                        const SizedBox(height: 10),
                        Text(
                          '${card.saved.contractId.substring(0, 8)}...${card.saved.contractId.substring(card.saved.contractId.length - 6)}',
                          style: bodyText(10, color: const Color(0xFF3A3C48)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _TandaCard {
  final SavedTanda saved;
  final TandaConfig? config;
  final int participantCount;

  const _TandaCard({
    required this.saved,
    this.config,
    this.participantCount = 0,
  });
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.08),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF3A3C48), size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: bodyText(12,
                    color: valueColor ?? offWhite,
                    weight: FontWeight.w600)),
            Text(label,
                style: bodyText(9, color: const Color(0xFF6B6D7B))),
          ],
        ),
      ],
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: bodyText(13, color: color, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
