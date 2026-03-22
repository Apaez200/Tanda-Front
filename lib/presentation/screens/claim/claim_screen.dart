import 'package:animate_do/animate_do.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../injection.dart';
import '../../../models/investment_pool_model.dart';
import '../../../models/tanda_config_model.dart';
import '../../../models/tanda_error_model.dart';
import '../../widgets/custom_button.dart';

class ClaimScreen extends StatelessWidget {
  const ClaimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClaimView();
  }
}

class ClaimView extends StatefulWidget {
  const ClaimView({super.key});

  @override
  State<ClaimView> createState() => _ClaimViewState();
}

class _ClaimViewState extends State<ClaimView> {
  late ConfettiController _confetti;
  final _fmt =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  bool _loadingClaim = false;
  final bool _loadingWait = false;
  bool _isLoading = true;
  String? _error;

  double _totalAvailable = 0;
  double _poolAmount = 0;
  double _yieldAmount = 0;
  double _collateralReserved = 0;
  double _cetesRetention = 0; // 10% retenido para inversión CETES
  double _claimableNow = 0;

  @override
  void initState() {
    super.initState();
    _confetti =
        ConfettiController(duration: const Duration(seconds: 8))..play();
    _loadClaimData();
  }

  Future<void> _loadClaimData() async {
    try {
      final results = await Future.wait([
        tandaRepository.getConfig(),
        tandaRepository.getCollateralPool(),
        tandaRepository.getRoundInfo(),
      ]);

      final config = results[0] as TandaConfig;
      final pool = results[1] as InvestmentPool;
      // roundInfo available at results[2] if needed

      final paymentPerPerson = config.paymentAmountMXN;
      final totalPool = paymentPerPerson * config.maxParticipants;
      final yield_ = pool.accumulatedYieldMXN;
      final collateral = paymentPerPerson * 0.10; // 10% collateral
      final available = totalPool + yield_;
      final cetesRetain = available * 0.10; // 10% del total se invierte en CETES
      final claimable = available - collateral - cetesRetain;

      if (mounted) {
        setState(() {
          _totalAvailable = available;
          _poolAmount = totalPool;
          _yieldAmount = yield_;
          _collateralReserved = collateral;
          _cetesRetention = cetesRetain;
          _claimableNow = claimable;
          _isLoading = false;
        });
      }
    } on TandaException catch (e) {
      debugPrint('[Claim] TandaException loading data: ${e.error.userMessage}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.error.userMessage;
        });
      }
    } catch (e) {
      debugPrint('[Claim] Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error cargando datos del cobro';
        });
      }
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _onClaimNow() async {
    setState(() => _loadingClaim = true);

    try {
      final secretKey = await walletRepository.getSavedSecretKey();
      if (secretKey == null || secretKey.isEmpty) {
        throw TandaException(TandaContractError.unknown,
            rawMessage: 'No wallet conectada');
      }

      final txHash =
          await tandaRepository.claimPayout(signerSecretKey: secretKey);

      if (!mounted) return;
      setState(() => _loadingClaim = false);
      showModalBottomSheet(
        context: context,
        backgroundColor: cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¡Cobrado!',
                  style: titleBold(24, color: successGreen)),
              const SizedBox(height: 8),
              Text('${_fmt.format(_claimableNow)} en camino a tu wallet',
                  style: bodyText(15, color: offWhite),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                  '${_fmt.format(_collateralReserved)} reservados como colateral',
                  style: bodyText(13, color: softGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                  '${_fmt.format(_cetesRetention)} invertidos en CETES fijos',
                  style: bodyText(13, color: accentGold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              SelectableText(
                'TX: ${txHash.substring(0, 16)}...',
                style: bodyText(11, color: softGray),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Ver historial',
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/history');
                },
                variant: CustomButtonVariant.primary,
                fullWidth: true,
              ),
            ],
          ),
        ),
      );
    } on TandaException catch (e) {
      if (mounted) {
        setState(() => _loadingClaim = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cardBg,
            content: Text(e.error.userMessage,
                style: bodyText(13, color: warningRed)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingClaim = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cardBg,
            content:
                Text('Error: $e', style: bodyText(13, color: warningRed)),
          ),
        );
      }
    }
  }

  void _onWaitMore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Estás completamente seguro?', style: titleBold(18)),
        content: Text(
          'Tu dinero quedará congelado hasta el ${_frozenDate()}.\nNo podrás retirar nada antes de esa fecha.',
          style: bodyText(14, color: softGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: bodyText(14, color: softGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, congelar mi dinero',
                style: bodyText(14,
                    color: warningRed, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.go('/frozen');
    }
  }

  String _frozenDate() {
    final d = DateTime.now().add(const Duration(days: 7));
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: darkBg,
        appBar: AppBar(
          title: Text('¡Es tu turno!', style: titleBold(20, color: accentGold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: accentGold),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: darkBg,
        appBar: AppBar(
          title: Text('¡Es tu turno!', style: titleBold(20, color: accentGold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
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
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadClaimData();
                  },
                  variant: CustomButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title:
            Text('¡Es tu turno!', style: titleBold(20, color: accentGold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.15,
              colors: const [
                accentGold,
                successGreen,
                offWhite,
                primaryGreen
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // MONTO DISPONIBLE
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accentGold.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                            color: accentGold.withOpacity(0.2),
                            blurRadius: 20),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text('Tienes disponible',
                            style: bodyText(14, color: softGray)),
                        const SizedBox(height: 8),
                        _AnimatedAmount(
                            target: _totalAvailable, fmt: _fmt),
                        const SizedBox(height: 12),
                        _desglose(
                            'Pool del grupo:', _fmt.format(_poolAmount)),
                        _desglose('Tu rendimiento extra:',
                            '+${_fmt.format(_yieldAmount)}',
                            green: true),
                        _desglose('Inversión CETES fijos:',
                            '-${_fmt.format(_cetesRetention)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // CARD A — COBRAR AHORA
                FadeInLeft(
                  delay: const Duration(milliseconds: 150),
                  child: _OptionCard(
                    borderColor: successGreen,
                    icon: Icons.monetization_on_rounded,
                    iconColor: successGreen,
                    title: 'Cobrar ahora',
                    amount: _fmt.format(_claimableNow),
                    subtitle:
                        '${_fmt.format(_collateralReserved)} colateral · ${_fmt.format(_cetesRetention)} a CETES',
                    buttonLabel: 'Cobrar ${_fmt.format(_claimableNow)}',
                    buttonVariant: CustomButtonVariant.secondary,
                    loading: _loadingClaim,
                    onPressed: _onClaimNow,
                  ),
                ),
                const SizedBox(height: 16),

                // CARD B — ESPERAR
                FadeInRight(
                  delay: const Duration(milliseconds: 200),
                  child: _OptionCard(
                    borderColor: accentGold,
                    icon: Icons.hourglass_bottom_rounded,
                    iconColor: accentGold,
                    title: 'Dejar 7 días más',
                    amount: '~${_fmt.format(_totalAvailable * 1.014)}',
                    subtitle: 'Ganarías rendimiento extra',
                    subtitleColor: successGreen,
                    buttonLabel: 'Entiendo, quiero esperar',
                    buttonVariant: CustomButtonVariant.primary,
                    loading: _loadingWait,
                    onPressed: _onWaitMore,
                    warning:
                        'Una vez que confirmes, tu dinero quedará BLOQUEADO 7 días sin posibilidad de retiro. No hay excepciones.',
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desglose(String l, String v, {bool green = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: bodyText(13, color: softGray)),
            Text(v,
                style: bodyText(13,
                    color: green ? successGreen : offWhite,
                    weight: FontWeight.w600)),
          ],
        ),
      );
}

// ─── ANIMATED AMOUNT ──────────────────────────────────────────────────────────

class _AnimatedAmount extends StatefulWidget {
  const _AnimatedAmount({required this.target, required this.fmt});
  final double target;
  final NumberFormat fmt;

  @override
  State<_AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<_AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _anim = Tween<double>(begin: 0, end: widget.target)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        widget.fmt.format(_anim.value),
        style: titleBold(40, color: accentGold),
      ),
    );
  }
}

// ─── OPTION CARD ───────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonVariant,
    required this.loading,
    required this.onPressed,
    this.subtitleColor,
    this.warning,
  });

  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String amount;
  final String subtitle;
  final Color? subtitleColor;
  final String buttonLabel;
  final CustomButtonVariant buttonVariant;
  final bool loading;
  final VoidCallback onPressed;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleSemi(17)),
                  Text(amount, style: titleBold(22, color: borderColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle,
              style: bodyText(13, color: subtitleColor ?? softGray)),
          if (warning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warningRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: warningRed.withOpacity(0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: warningRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(warning!,
                          style: bodyText(12, color: warningRed))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          CustomButton(
            label: buttonLabel,
            onPressed: onPressed,
            variant: buttonVariant,
            loading: loading,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
