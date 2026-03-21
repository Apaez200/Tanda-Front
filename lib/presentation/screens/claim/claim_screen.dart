import 'package:animate_do/animate_do.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';

class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  late ConfettiController _confetti;
  final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  bool _loadingClaim = false;
  bool _loadingWait = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 8))..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _onClaimNow() async {
    setState(() => _loadingClaim = true);
    await Future.delayed(const Duration(milliseconds: 2000));
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
            Text('🎉 ¡Cobrado!', style: syneBold(24, color: successGreen)),
            const SizedBox(height: 8),
            Text('\$4,950 en camino a tu wallet', style: dmSans(15, color: offWhite), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('\$200 ya reservados para la siguiente ronda 🔒', style: dmSans(13, color: softGray), textAlign: TextAlign.center),
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
  }

  void _onWaitMore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Estás completamente seguro?', style: syneBold(18)),
        content: Text(
          'Tu dinero quedará congelado hasta el ${_frozenDate()}.\nNo podrás retirar nada antes de esa fecha.',
          style: dmSans(14, color: softGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: dmSans(14, color: softGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, congelar mi dinero', style: dmSans(14, color: warningRed, weight: FontWeight.w700)),
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
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text('¡Es tu turno! 🏆', style: syneBold(20, color: accentGold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.15,
              colors: const [accentGold, successGreen, offWhite, primaryGreen],
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
                      border: Border.all(color: accentGold.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(color: accentGold.withOpacity(0.2), blurRadius: 20),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text('Tienes disponible', style: dmSans(14, color: softGray)),
                        const SizedBox(height: 8),
                        _AnimatedAmount(target: 5150.0, fmt: _fmt),
                        const SizedBox(height: 12),
                        _desglose('Pool del grupo:', '\$5,000.00'),
                        _desglose('Tu rendimiento extra:', '+\$150.00 ✨', green: true),
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
                    amount: '\$4,950.00',
                    subtitle: '\$200 se quedan guardados para tu lugar en la próxima tanda 🔒',
                    buttonLabel: 'Cobrar \$4,950 →',
                    buttonVariant: CustomButtonVariant.secondary,
                    loading: _loadingClaim,
                    onPressed: _onClaimNow,
                  ),
                ),
                const SizedBox(height: 16),

                // CARD B — ESPERAR
                FadeInRight(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      _OptionCard(
                        borderColor: accentGold,
                        icon: Icons.hourglass_bottom_rounded,
                        iconColor: accentGold,
                        title: 'Dejar 7 días más',
                        amount: '~\$5,220.00',
                        subtitle: 'Ganarías ~\$70 extra',
                        subtitleColor: successGreen,
                        buttonLabel: 'Entiendo, quiero esperar',
                        buttonVariant: CustomButtonVariant.primary,
                        loading: _loadingWait,
                        onPressed: _onWaitMore,
                        warning: 'Una vez que confirmes, tu dinero quedará BLOQUEADO 7 días sin posibilidad de retiro. No hay excepciones.',
                      ),
                    ],
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
            Text(l, style: dmSans(13, color: softGray)),
            Text(v, style: dmSans(13, color: green ? successGreen : offWhite, weight: FontWeight.w600)),
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
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
        style: syneBold(40, color: accentGold),
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
                  Text(title, style: syneSemi(17)),
                  Text(amount, style: syneBold(22, color: borderColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: dmSans(13, color: subtitleColor ?? softGray)),
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
                  const Icon(Icons.warning_amber_rounded, color: warningRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(warning!, style: dmSans(12, color: warningRed))),
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
