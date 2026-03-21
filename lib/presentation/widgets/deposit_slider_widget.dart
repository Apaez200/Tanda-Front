import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock/mock_data.dart';

typedef DepositProjection = ({int day, int daysInvested, double projectedYield});

class DepositSliderWidget extends StatefulWidget {
  const DepositSliderWidget({
    super.key,
    required this.minDay,
    required this.maxDay,
    required this.amount,
    required this.dailyNetAPY,
    required this.todayDay,
    required this.onProjectionChanged,
  });

  final int minDay;
  final int maxDay;
  final double amount;
  final double dailyNetAPY;
  final int todayDay;
  final ValueChanged<DepositProjection> onProjectionChanged;

  @override
  State<DepositSliderWidget> createState() => _DepositSliderWidgetState();
}

class _DepositSliderWidgetState extends State<DepositSliderWidget> {
  late double _day;

  @override
  void initState() {
    super.initState();
    _day = widget.todayDay.toDouble().clamp(widget.minDay.toDouble(), widget.maxDay.toDouble());
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  void _emit() {
    final day = _day.round().clamp(widget.minDay, widget.maxDay);
    final cutoff = mockTanda.cutoffDay;
    final daysInvested = (cutoff - day).clamp(1, cutoff);
    final projected = widget.amount * widget.dailyNetAPY * daysInvested;
    widget.onProjectionChanged((day: day, daysInvested: daysInvested, projectedYield: projected));
  }

  String _motivation(int day) {
    if (day <= 10) return '🚀 ¡Excelente! Máximo rendimiento';
    if (day <= 20) return '👍 Buen momento para depositar';
    return '⏰ Aún a tiempo, aunque menos rendimiento';
  }

  @override
  Widget build(BuildContext context) {
    final day = _day.round().clamp(widget.minDay, widget.maxDay);
    final cutoff = mockTanda.cutoffDay;
    final daysInvested = (cutoff - day).clamp(1, cutoff);
    final projected = widget.amount * widget.dailyNetAPY * daysInvested;
    final span = (widget.maxDay - widget.minDay).clamp(1, 1000);
    final progress = (day - widget.minDay) / span;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hoy (día ${widget.todayDay})', style: bodyText(12, color: softGray)),
            Text('Día ${widget.maxDay}', style: bodyText(12, color: softGray)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentGold,
            inactiveTrackColor: softGray.withOpacity(0.35),
            thumbColor: accentGold,
            overlayColor: accentGold.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            min: widget.minDay.toDouble(),
            max: widget.maxDay.toDouble(),
            divisions: widget.maxDay - widget.minDay,
            value: _day,
            onChanged: (v) {
              setState(() => _day = v);
              _emit();
            },
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: cardBg,
            color: accentGold,
          ),
        ),
        const SizedBox(height: 12),
        Text('Días invertidos: $daysInvested', style: bodyText(14, color: offWhite)),
        const SizedBox(height: 4),
        Text(
          'Rendimiento estimado: +${projected.toStringAsFixed(2)}',
          style: bodyText(15, color: successGreen, weight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(_motivation(day), style: bodyText(13, color: accentGold)),
      ],
    );
  }
}
