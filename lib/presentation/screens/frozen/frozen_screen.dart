import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_data.dart';
import '../../widgets/countdown_widget.dart';
import '../../widgets/yield_counter_widget.dart';

class FrozenScreen extends StatefulWidget {
  const FrozenScreen({super.key});

  @override
  State<FrozenScreen> createState() => _FrozenScreenState();
}

class _FrozenScreenState extends State<FrozenScreen>
    with SingleTickerProviderStateMixin {
  late final DateTime _unlockDate;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  final _fmtDate = DateFormat('dd/MM/yyyy HH:mm');

  int _quoteIndex = 0;
  Timer? _quoteTimer;

  final _quotes = [
    'Tu paciencia tiene recompensa 💪',
    'Los CETES están trabajando para ti 📈',
    '¡Aguanta! Tu dinero crece cada segundo 🎯',
    'Quedan pocos días y cobras más 🚀',
  ];

  @override
  void initState() {
    super.initState();
    _unlockDate = DateTime.now().add(const Duration(days: 7));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _quoteTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _quoteIndex = (_quoteIndex + 1) % _quotes.length);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _quoteTimer?.cancel();
    super.dispose();
  }

  // Progreso de los 7 días transcurrido desde que entró a esta pantalla
  // (para demo, mostramos 0 al inicio — en real se guardaría el timestamp)
  double get _progress => 0.0;

  @override
  Widget build(BuildContext context) {
    const frozenAmount = 5150.0;
    // Incremento cada 10s: monto * APY / (86400 / 10)
    final incPer10s = frozenAmount * mockDailyNetAPY / 8640;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text('Fondos Bloqueados 🔒', style: titleBold(20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ICONO CANDADO PULSANTE
            FadeIn(
              child: Center(
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentGold.withOpacity(0.12),
                      border: Border.all(color: accentGold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: accentGold.withOpacity(0.3),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_rounded, color: accentGold, size: 52),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // COUNTDOWN REAL
            FadeInUp(delay: const Duration(milliseconds: 100), child: _sectionLabel('Tu dinero se desbloquea en:')),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: CountdownWidget(
                targetDateTime: _unlockDate,
                numberColor: accentGold,
                boxColor: const Color(0xFF1F1800),
              ),
            ),
            const SizedBox(height: 24),

            // MONTO Y RENDIMIENTO
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentGold.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Monto bloqueado', _fmt.format(frozenAmount)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rendimiento generando', style: bodyText(14, color: softGray)),
                        Row(
                          children: [
                            Text('+', style: bodyText(14, color: successGreen, weight: FontWeight.w600)),
                            YieldCounterWidget(
                              initialValue: 0,
                              incrementPerTick: incPer10s,
                              tickSeconds: 10,
                              format: (v) => v.toStringAsFixed(4),
                              textStyle: bodyText(14, color: successGreen, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Barra de 7 días
                    Text('Progreso de espera', style: bodyText(12, color: softGray)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFF2A2A2A),
                        color: accentGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Día 0', style: bodyText(11, color: softGray)),
                        Text('Día 7', style: bodyText(11, color: softGray)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // FRASE MOTIVACIONAL
            FadeInUp(
              delay: const Duration(milliseconds: 280),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                child: Container(
                  key: ValueKey(_quoteIndex),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    _quotes[_quoteIndex],
                    style: bodyText(15, color: offWhite),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // BOTÓN DESHABILITADO
            Tooltip(
              message:
                  'Tu dinero estará disponible el ${_fmtDate.format(_unlockDate)}',
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: softGray.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: softGray.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Disponible el ${_fmtDate.format(_unlockDate)}',
                  style: bodyText(15, color: softGray),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: titleSemi(16));

  Widget _row(String l, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: bodyText(14, color: softGray)),
          Text(v, style: bodyText(14, color: offWhite, weight: FontWeight.w600)),
        ],
      );
}
