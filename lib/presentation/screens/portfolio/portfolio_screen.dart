import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const _bg = Color(0xFF060608);
const _cardColor = Color(0xFF0E0F14);
const _borderColor = Color(0xFF1E1F2A);
const _mint = Color(0xFF0CFFC5);
const _purple = Color(0xFF6C63FF);

class PortfolioScreen extends StatefulWidget {
  final double balance;
  final int activeTandas;
  final int completedTandas;

  const PortfolioScreen({
    super.key,
    required this.balance,
    required this.activeTandas,
    required this.completedTandas,
  });

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _chartAnim;
  final _fmt =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _chartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _chartAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estimatedYield = widget.balance * 0.09; // ~9% anual
    final monthlyYield = estimatedYield / 12;

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
            Text('Mi portafolio', style: titleSemi(18, color: offWhite)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── BALANCE GRANDE ──
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF141520), Color(0xFF0E0F14)],
                    ),
                    border: Border.all(
                        color: _mint.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Balance total',
                          style: bodyText(13,
                              color: const Color(0xFF6B6D7B))),
                      const SizedBox(height: 4),
                      Text(_fmt.format(widget.balance),
                          style: titleBold(38, color: offWhite)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _mint.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.trending_up_rounded,
                                    color: _mint, size: 14),
                                const SizedBox(width: 4),
                                Text('+9.0% anual',
                                    style: bodyText(11,
                                        color: _mint,
                                        weight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('USDC',
                              style: bodyText(12,
                                  color: const Color(0xFF4A4B55),
                                  weight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── STATS ROW ──
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Rendimiento\nestimado/mes',
                        value: _fmt.format(monthlyYield),
                        icon: Icons.show_chart_rounded,
                        color: _mint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Rendimiento\nestimado/anual',
                        value: _fmt.format(estimatedYield),
                        icon: Icons.insights_rounded,
                        color: accentGold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 80),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Tandas\nactivas',
                        value: '${widget.activeTandas}',
                        icon: Icons.people_rounded,
                        color: _purple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Tandas\ncompletadas',
                        value: '${widget.completedTandas}',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF6B6D7B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── GRAFICO DE RENDIMIENTO ──
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 150),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.show_chart_rounded,
                              color: _mint, size: 18),
                          const SizedBox(width: 8),
                          Text('Crecimiento proyectado',
                              style: titleSemi(14, color: offWhite)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Basado en rendimiento ~9% anual (CETES)',
                          style: bodyText(11,
                              color: const Color(0xFF6B6D7B))),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _chartAnim,
                        builder: (context, _) {
                          return SizedBox(
                            height: 180,
                            child: CustomPaint(
                              size: const Size(double.infinity, 180),
                              painter: _YieldChartPainter(
                                progress: _chartAnim.value,
                                balance: widget.balance,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Hoy',
                              style: bodyText(10,
                                  color: const Color(0xFF6B6D7B))),
                          Text('3 meses',
                              style: bodyText(10,
                                  color: const Color(0xFF6B6D7B))),
                          Text('6 meses',
                              style: bodyText(10,
                                  color: const Color(0xFF6B6D7B))),
                          Text('12 meses',
                              style: bodyText(10,
                                  color: const Color(0xFF6B6D7B))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── DISTRIBUCION ──
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 250),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pie_chart_outline_rounded,
                              color: accentGold, size: 18),
                          const SizedBox(width: 8),
                          Text('Tu dinero trabaja asi',
                              style: titleSemi(14, color: offWhite)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AnimatedBuilder(
                        animation: _chartAnim,
                        builder: (context, _) {
                          return SizedBox(
                            height: 140,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: CustomPaint(
                                    painter: _DonutChartPainter(
                                      progress: _chartAnim.value,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      _LegendItem(
                                        color: accentGold,
                                        label: 'CETES (inv.)',
                                        percentage: '90%',
                                      ),
                                      const SizedBox(height: 12),
                                      _LegendItem(
                                        color: _purple,
                                        label: 'Colateral',
                                        percentage: '10%',
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _mint
                                              .withValues(alpha: 0.06),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons
                                                    .security_rounded,
                                                color: _mint,
                                                size: 14),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Protegido por smart contract',
                                                style: bodyText(10,
                                                    color: _mint,
                                                    weight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── PROYECCION TABLA ──
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 350),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              color: _purple, size: 18),
                          const SizedBox(width: 8),
                          Text('Proyeccion de rendimientos',
                              style: titleSemi(14, color: offWhite)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ProjectionRow(
                        period: '1 mes',
                        amount: _fmt.format(
                            widget.balance + monthlyYield),
                        yield_: _fmt.format(monthlyYield),
                        color: _mint,
                      ),
                      _ProjectionRow(
                        period: '3 meses',
                        amount: _fmt.format(
                            widget.balance + monthlyYield * 3),
                        yield_: _fmt.format(monthlyYield * 3),
                        color: _mint,
                      ),
                      _ProjectionRow(
                        period: '6 meses',
                        amount: _fmt.format(
                            widget.balance + monthlyYield * 6),
                        yield_: _fmt.format(monthlyYield * 6),
                        color: accentGold,
                      ),
                      _ProjectionRow(
                        period: '12 meses',
                        amount: _fmt.format(
                            widget.balance + estimatedYield),
                        yield_: _fmt.format(estimatedYield),
                        color: accentGold,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PAINTERS ───────────────────────────────────────────────────────────────

class _YieldChartPainter extends CustomPainter {
  final double progress;
  final double balance;

  _YieldChartPainter({required this.progress, required this.balance});

  @override
  void paint(Canvas canvas, Size size) {
    final monthlyRate = 0.09 / 12;
    final points = <Offset>[];
    final effectiveBalance = balance <= 0 ? 1000.0 : balance;

    for (int i = 0; i <= 12; i++) {
      final x = (i / 12) * size.width;
      final projected = effectiveBalance * pow(1 + monthlyRate, i);
      final maxProjected = effectiveBalance * pow(1 + monthlyRate, 12);
      final minVal = effectiveBalance * 0.95;
      final range = maxProjected - minVal;
      final y = range == 0
          ? size.height * 0.5
          : size.height - ((projected - minVal) / range * size.height * 0.85) - size.height * 0.08;
      points.add(Offset(x, y));
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1B24)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3.5) + size.height * 0.05;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gradient fill
    final animatedCount = (points.length * progress).round().clamp(2, points.length);
    final animatedPoints = points.sublist(0, animatedCount);

    if (animatedPoints.length >= 2) {
      final fillPath = Path()
        ..moveTo(animatedPoints.first.dx, size.height)
        ..lineTo(animatedPoints.first.dx, animatedPoints.first.dy);

      for (int i = 1; i < animatedPoints.length; i++) {
        final prev = animatedPoints[i - 1];
        final curr = animatedPoints[i];
        final cp1x = prev.dx + (curr.dx - prev.dx) * 0.5;
        fillPath.cubicTo(cp1x, prev.dy, cp1x, curr.dy, curr.dx, curr.dy);
      }
      fillPath.lineTo(animatedPoints.last.dx, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mint.withValues(alpha: 0.15),
            _mint.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);

      // Line
      final linePath = Path()
        ..moveTo(animatedPoints.first.dx, animatedPoints.first.dy);
      for (int i = 1; i < animatedPoints.length; i++) {
        final prev = animatedPoints[i - 1];
        final curr = animatedPoints[i];
        final cp1x = prev.dx + (curr.dx - prev.dx) * 0.5;
        linePath.cubicTo(cp1x, prev.dy, cp1x, curr.dy, curr.dx, curr.dy);
      }

      final linePaint = Paint()
        ..color = _mint
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, linePaint);

      // End dot
      final lastPoint = animatedPoints.last;
      canvas.drawCircle(
          lastPoint, 5, Paint()..color = _mint.withValues(alpha: 0.2));
      canvas.drawCircle(lastPoint, 3, Paint()..color = _mint);
    }
  }

  @override
  bool shouldRepaint(covariant _YieldChartPainter old) =>
      old.progress != progress;
}

class _DonutChartPainter extends CustomPainter {
  final double progress;
  _DonutChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 20.0;

    // Background ring
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1B24)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // CETES slice (90%)
    final cetesPaint = Paint()
      ..color = accentGold
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cetesAngle = 2 * pi * 0.90 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      cetesAngle,
      false,
      cetesPaint,
    );

    // Collateral slice (10%)
    final colPaint = Paint()
      ..color = _purple
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final colStart = -pi / 2 + cetesAngle + 0.05;
    final colAngle = 2 * pi * 0.10 * progress;
    if (progress > 0.1) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        colStart,
        colAngle,
        false,
        colPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.progress != progress;
}

// ─── WIDGETS ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: titleBold(18, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: bodyText(11, color: const Color(0xFF6B6D7B))),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: bodyText(12, color: const Color(0xFF6B6D7B))),
        ),
        Text(percentage,
            style:
                bodyText(13, color: offWhite, weight: FontWeight.w600)),
      ],
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  final String period;
  final String amount;
  final String yield_;
  final Color color;

  const _ProjectionRow({
    required this.period,
    required this.amount,
    required this.yield_,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0B10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today_rounded,
                color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period,
                    style: bodyText(13,
                        color: offWhite, weight: FontWeight.w600)),
                Text('Balance: $amount',
                    style: bodyText(11,
                        color: const Color(0xFF6B6D7B))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(yield_,
                  style: bodyText(13,
                      color: color, weight: FontWeight.w700)),
              Text('ganancia',
                  style: bodyText(10,
                      color: const Color(0xFF4A4B55))),
            ],
          ),
        ],
      ),
    );
  }
}
