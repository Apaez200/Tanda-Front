import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/contract_constants.dart';
import '../../../data/implementations/soroban/soroban_wallet_repository.dart';
import '../../../data/services/accesly_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/tanda_storage_service.dart';
import '../../../injection.dart';
import '../../../models/tanda_config_model.dart';
import '../../../models/participant_info_model.dart';
import '../../../models/tanda_error_model.dart';
import '../../widgets/custom_button.dart';

const _bg = Color(0xFF060608);
const _cardColor = Color(0xFF0E0F14);
const _borderColor = Color(0xFF1E1F2A);
const _mint = Color(0xFF0CFFC5);
const _purple = Color(0xFF6C63FF);

// ─── TOP-LEVEL HELPER ─────────────────────────────────────────────────────────

String _fmtPeriod(int secs) {
  if (secs >= 86400) {
    final days = secs ~/ 86400;
    return '$days ${days == 1 ? "dia" : "dias"}';
  }
  final hours = secs ~/ 3600;
  return '$hours ${hours == 1 ? "hora" : "horas"}';
}

// ─── DATA CLASS ───────────────────────────────────────────────────────────────

class _DiscoverableTanda {
  final String name;
  final String contractId;
  final int participants;
  final int maxParticipants;
  final double paymentAmount;
  final String period;
  final String category;
  bool get isFull => participants >= maxParticipants;

  const _DiscoverableTanda({
    required this.name,
    required this.contractId,
    required this.participants,
    required this.maxParticipants,
    required this.paymentAmount,
    required this.period,
    required this.category,
  });
}

// ─── MAIN SCREEN ──────────────────────────────────────────────────────────────

class JoinTandaScreen extends StatefulWidget {
  const JoinTandaScreen({super.key});

  @override
  State<JoinTandaScreen> createState() => _JoinTandaScreenState();
}

class _JoinTandaScreenState extends State<JoinTandaScreen> {
  final _contractIdController = TextEditingController();
  final _searchController = TextEditingController();
  final _fmt =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

  bool _isLoading = false;
  bool _showContractSearch = false;
  String _selectedFilter = 'Todas';

  final _filters = [
    'Todas',
    'Disponibles',
    'Semanal',
    'Quincenal',
    'Mensual',
  ];

  // Todas apuntan al contrato real desplegado en testnet
  // En producción, estos datos vendrían de un indexer on-chain
  final _availableTandas = <_DiscoverableTanda>[
    _DiscoverableTanda(
      name: 'Tanda Amigos CDMX',
      contractId: ContractConstants.tandaContractId,
      participants: 3,
      maxParticipants: 5,
      paymentAmount: 1000,
      period: 'Mensual',
      category: 'Mensual',
    ),
  ];

  @override
  void dispose() {
    _contractIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_DiscoverableTanda> get _filteredTandas {
    var list = _availableTandas.toList();
    final search = _searchController.text.toLowerCase();

    if (search.isNotEmpty) {
      list = list
          .where((t) => t.name.toLowerCase().contains(search))
          .toList();
    }

    if (_selectedFilter == 'Disponibles') {
      list = list.where((t) => !t.isFull).toList();
    } else if (_selectedFilter != 'Todas') {
      list = list.where((t) => t.category == _selectedFilter).toList();
    }

    return list;
  }

  Future<void> _loadTandaInfo(String contractId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      setActiveTandaContract(contractId);
      final myAddress = await walletRepository.getConnectedPublicKey();
      final config = await tandaRepository.getConfig();
      List<ParticipantInfo> participants = [];

      try {
        participants = await tandaRepository.getAllParticipants();
      } catch (e) {
        debugPrint('[Join] Error loading participants: $e');
      }

      bool registered = false;
      for (final p in participants) {
        if (p.address == myAddress) {
          registered = true;
          break;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _showTandaDetail(
          contractId: contractId,
          config: config,
          participants: participants,
          myAddress: myAddress,
          alreadyRegistered: registered,
        );
      }
    } on TandaException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.error.userMessage, warningRed);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('No se pudo cargar la tanda', warningRed);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: bodyText(13, color: color)),
      ),
    );
  }

  void _showTandaDetail({
    required String contractId,
    required TandaConfig config,
    required List<ParticipantInfo> participants,
    required String? myAddress,
    required bool alreadyRegistered,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TandaDetailSheet(
        config: config,
        participants: participants,
        myAddress: myAddress,
        alreadyRegistered: alreadyRegistered,
        contractId: contractId,
        fmt: _fmt,
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTandas;
    final fmtShort =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

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
                color: _mint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('Unirse a Tanda', style: titleSemi(18, color: offWhite)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () =>
                setState(() => _showContractSearch = !_showContractSearch),
            icon: Icon(
              _showContractSearch
                  ? Icons.explore_rounded
                  : Icons.receipt_long_rounded,
              color: const Color(0xFF6B6D7B),
              size: 22,
            ),
            tooltip: _showContractSearch
                ? 'Ver tandas disponibles'
                : 'Buscar por Contract ID',
          ),
        ],
      ),
      body: SafeArea(
        child: _showContractSearch
            ? _buildContractSearch()
            : _buildDiscovery(filtered, fmtShort),
      ),
    );
  }

  // ── CONTRACT SEARCH VIEW ──────────────────────────────────────────────────

  Widget _buildContractSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: Text(
              'Tienes un codigo de invitacion? Pegalo aqui.',
              style: bodyText(14, color: const Color(0xFF6B6D7B)),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contract ID',
                      style: bodyText(11,
                          color: const Color(0xFF6B6D7B),
                          weight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    child: TextField(
                      controller: _contractIdController,
                      style: bodyText(13, color: accentGold),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Pega el Contract ID aqui...',
                        hintStyle:
                            bodyText(13, color: const Color(0xFF3A3C48)),
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) _loadTandaInfo(v.trim());
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            final id = _contractIdController.text.trim();
                            if (id.isNotEmpty) _loadTandaInfo(id);
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [_mint, Color(0xFF08B88E)],
                        ),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _bg),
                              )
                            : Text('Buscar tanda',
                                style: bodyText(15,
                                    color: _bg,
                                    weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DISCOVERY VIEW ────────────────────────────────────────────────────────

  Widget _buildDiscovery(
      List<_DiscoverableTanda> filtered, NumberFormat fmtShort) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: Color(0xFF4A4B55), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: bodyText(14, color: offWhite),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Buscar tandas...',
                        hintStyle:
                            bodyText(14, color: const Color(0xFF3A3C48)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: const Icon(Icons.close_rounded,
                          color: Color(0xFF4A4B55), size: 18),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Filter chips
        SizedBox(
          height: 36,
          child: FadeInDown(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 50),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final selected = _selectedFilter == f;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? _mint.withValues(alpha: 0.12)
                          : _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? _mint.withValues(alpha: 0.4)
                            : _borderColor,
                      ),
                    ),
                    child: Center(
                      child: Text(f,
                          style: bodyText(12,
                              color: selected
                                  ? _mint
                                  : const Color(0xFF6B6D7B),
                              weight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text(
                  '${filtered.length} tanda${filtered.length == 1 ? '' : 's'}',
                  style: bodyText(12,
                      color: const Color(0xFF6B6D7B),
                      weight: FontWeight.w500)),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _mint),
                ),
            ],
          ),
        ),

        // Tandas list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          color: Color(0xFF3A3C48), size: 40),
                      const SizedBox(height: 12),
                      Text('No se encontraron tandas',
                          style: bodyText(14, color: softGray)),
                      const SizedBox(height: 4),
                      Text('Intenta con otro filtro o busca por codigo',
                          style: bodyText(12,
                              color: const Color(0xFF4A4B55))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final t = filtered[i];
                    final spots = t.maxParticipants - t.participants;
                    final progress = t.participants / t.maxParticipants;

                    return FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: i * 60),
                      child: GestureDetector(
                        onTap: () => _loadTandaInfo(t.contractId),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: t.isFull
                                  ? _borderColor
                                  : _mint.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      color: t.isFull
                                          ? softGray.withValues(alpha: 0.1)
                                          : _mint.withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      Icons.savings_rounded,
                                      color: t.isFull ? softGray : _mint,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(t.name,
                                            style: titleSemi(14,
                                                color: offWhite)),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1),
                                              decoration: BoxDecoration(
                                                color: (t.isFull
                                                        ? softGray
                                                        : _mint)
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                t.isFull
                                                    ? 'Llena'
                                                    : '$spots lugares',
                                                style: bodyText(9,
                                                    color: t.isFull
                                                        ? softGray
                                                        : _mint,
                                                    weight: FontWeight.w700),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(t.period,
                                                style: bodyText(10,
                                                    color: _purple,
                                                    weight: FontWeight.w500)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          fmtShort.format(t.paymentAmount),
                                          style: titleSemi(14,
                                              color: accentGold)),
                                      Text('por ronda',
                                          style: bodyText(9,
                                              color:
                                                  const Color(0xFF4A4B55))),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor:
                                      const Color(0xFF1A1B24),
                                  color: t.isFull ? softGray : _mint,
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '${t.participants}/${t.maxParticipants} participantes',
                                    style: bodyText(10,
                                        color: const Color(0xFF6B6D7B)),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: (t.isFull ? softGray : _mint)
                                        .withValues(alpha: 0.5),
                                    size: 12,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── TANDA DETAIL BOTTOM SHEET ────────────────────────────────────────────────

class _TandaDetailSheet extends StatefulWidget {
  final TandaConfig config;
  final List<ParticipantInfo> participants;
  final String? myAddress;
  final bool alreadyRegistered;
  final String contractId;
  final NumberFormat fmt;

  const _TandaDetailSheet({
    required this.config,
    required this.participants,
    required this.myAddress,
    required this.alreadyRegistered,
    required this.contractId,
    required this.fmt,
  });

  @override
  State<_TandaDetailSheet> createState() => _TandaDetailSheetState();
}

class _TandaDetailSheetState extends State<_TandaDetailSheet> {
  bool _registering = false;
  String? _error;

  Future<void> _doRegister() async {
    if (_registering) return; // guard against double-clicks
    setState(() {
      _registering = true;
      _error = null;
    });

    try {
      final secretKey = await walletRepository.getSavedSecretKey() ?? '';
      final hasAccesly = kIsWeb && AcceslyService().isConnected;
      debugPrint(
          '[REGISTER-SHEET] secretKey: ${secretKey.isNotEmpty}, accesly: $hasAccesly');

      if (secretKey.isEmpty && !hasAccesly) {
        setState(() {
          _registering = false;
          _error = 'Conecta tu wallet primero';
        });
        return;
      }

      // Step 1: USDC Trustline
      if (walletRepository is SorobanWalletRepository) {
        if (secretKey.isNotEmpty) {
          debugPrint('[REGISTER-SHEET] Creando trustline USDC (local)...');
          await (walletRepository as SorobanWalletRepository)
              .ensureUsdcTrustline(signerSecretKey: secretKey);
        } else if (hasAccesly) {
          debugPrint('[REGISTER-SHEET] Creando trustline USDC (Accesly)...');
          await (walletRepository as SorobanWalletRepository)
              .ensureUsdcTrustlineViaAccesly();
        }
      }

      // Step 2: Register on contract
      debugPrint('[REGISTER-SHEET] Llamando register()...');
      setActiveTandaContract(widget.contractId);
      final txHash =
          await tandaRepository.register(signerSecretKey: secretKey);
      debugPrint('[REGISTER-SHEET] TX: $txHash');

      // Step 3: Save locally
      await tandaStorage.saveTanda(SavedTanda(
        contractId: widget.contractId,
        name: 'Tanda de Ahorro',
        role: 'member',
        joinedAt: DateTime.now(),
      ));

      // Step 4: Close sheet, notify, navigate
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _cardColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('Registrado exitosamente',
                style: bodyText(13, color: _mint)),
          ),
        );
        context.go('/dashboard');
      }
    } on TandaException catch (e) {
      debugPrint('[REGISTER-SHEET] TandaException: ${e.error.userMessage}');
      if (mounted) {
        setState(() {
          _registering = false;
          _error = e.error.userMessage;
        });
      }
    } catch (e) {
      debugPrint('[REGISTER-SHEET] Error: $e');
      if (mounted) {
        setState(() {
          _registering = false;
          _error = 'Error al registrarse: ${e.toString().split('\n').first}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final spots = config.maxParticipants - widget.participants.length;
    final paymentMXN = config.paymentAmount / 1000000;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          _mint.withValues(alpha: 0.15),
                          _mint.withValues(alpha: 0.05),
                        ],
                      ),
                      border:
                          Border.all(color: _mint.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.savings_rounded,
                        color: _mint, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tanda de Ahorro', style: titleSemi(18)),
                        const SizedBox(height: 4),
                        _StatusTag(status: config.status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(height: 1, color: _borderColor),
              const SizedBox(height: 20),

              // Detail rows
              _DetailRow(
                icon: Icons.people_alt_rounded,
                label: 'Participantes',
                value:
                    '${widget.participants.length} / ${config.maxParticipants}',
                valueColor: spots > 0 ? _mint : softGray,
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.paid_rounded,
                label: 'Pago por ronda',
                value: widget.fmt.format(paymentMXN),
                valueColor: accentGold,
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.timer_rounded,
                label: 'Periodo',
                value: _fmtPeriod(config.periodSecs),
                valueColor: offWhite,
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.sync_rounded,
                label: 'Rondas totales',
                value: '${config.totalRounds}',
                valueColor: offWhite,
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.shield_outlined,
                label: 'Colateral',
                value: '${config.collateralBps ~/ 100}%',
                valueColor: offWhite,
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.trending_up_rounded,
                label: 'Inversion',
                value: 'CETES (Etherfuse)',
                valueColor: _purple,
              ),
              const SizedBox(height: 20),

              // Availability banner
              _AvailabilityBanner(
                spots: spots,
                status: config.status,
              ),
              const SizedBox(height: 16),

              // Participants list
              if (widget.participants.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.group_rounded,
                              color: softGray, size: 16),
                          const SizedBox(width: 8),
                          Text('Registrados',
                              style: bodyText(13,
                                  color: softGray,
                                  weight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(widget.participants.length, (i) {
                        final p = widget.participants[i];
                        final isMe = p.address == widget.myAddress;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? _mint.withValues(alpha: 0.05)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isMe
                                ? Border.all(
                                    color: _mint.withValues(alpha: 0.15))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? _mint.withValues(alpha: 0.15)
                                      : const Color(0xFF1A1B24),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: bodyText(12,
                                          color: isMe ? _mint : softGray,
                                          weight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isMe
                                      ? 'Tu'
                                      : '${p.address.substring(0, 6)}...${p.address.substring(p.address.length - 4)}',
                                  style: bodyText(13,
                                      color: isMe ? _mint : offWhite),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Proof of funds notice
              if (!widget.alreadyRegistered &&
                  config.status == TandaStatus.registering &&
                  spots > 0)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accentGold.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: accentGold.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: accentGold, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Requisito: balance minimo de ${widget.fmt.format(paymentMXN * 2)} USDC.',
                          style: bodyText(12, color: accentGold),
                        ),
                      ),
                    ],
                  ),
                ),

              // Inline error message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: warningRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: warningRed.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: warningRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: bodyText(12, color: warningRed)),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Action button
              widget.alreadyRegistered
                  ? _GradientButton(
                      label: 'Ya estas registrado — Ir al Dashboard',
                      colors: const [_purple, Color(0xFF4E47B8)],
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/dashboard');
                      },
                    )
                  : (config.status == TandaStatus.registering && spots > 0)
                      ? _GradientButton(
                          label: _registering
                              ? 'Registrando...'
                              : 'Registrarme en esta Tanda',
                          colors: _registering
                              ? const [Color(0xFF3A3C48), Color(0xFF2A2B35)]
                              : const [_mint, Color(0xFF08B88E)],
                          onTap: _registering ? null : _doRegister,
                          loading: _registering,
                        )
                      : CustomButton(
                          label: 'Registro no disponible',
                          onPressed: null,
                          variant: CustomButtonVariant.disabled,
                          fullWidth: true,
                        ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── REUSABLE HELPER WIDGETS ──────────────────────────────────────────────────

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});
  final TandaStatus status;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    switch (status) {
      case TandaStatus.registering:
        label = 'REGISTRANDO';
        color = _mint;
      case TandaStatus.active:
        label = 'ACTIVA';
        color = successGreen;
      case TandaStatus.completed:
        label = 'COMPLETADA';
        color = softGray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: bodyText(9, color: color, weight: FontWeight.w700)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3A3C48), size: 18),
        const SizedBox(width: 10),
        Text(label, style: bodyText(13, color: const Color(0xFF6B6D7B))),
        const Spacer(),
        Text(value,
            style:
                bodyText(13, color: valueColor, weight: FontWeight.w600)),
      ],
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  const _AvailabilityBanner({required this.spots, required this.status});
  final int spots;
  final TandaStatus status;

  @override
  Widget build(BuildContext context) {
    final bool available = spots > 0 && status == TandaStatus.registering;
    final color = available ? _mint : warningRed;
    final text = available
        ? '$spots ${spots == 1 ? "lugar disponible" : "lugares disponibles"}'
        : status != TandaStatus.registering
            ? 'Esta tanda ya no acepta registros'
            : 'No hay lugares disponibles';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.block_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(text,
              style: bodyText(13, color: color, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.colors,
    this.onTap,
    this.loading = false,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: colors),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(label,
                  style: bodyText(15,
                      color: const Color(0xFF060608),
                      weight: FontWeight.w700)),
        ),
      ),
    );
  }
}
