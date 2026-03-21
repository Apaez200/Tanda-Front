import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CountdownWidget extends StatefulWidget {
  const CountdownWidget({
    super.key,
    required this.targetDateTime,
    this.onComplete,
    this.boxColor = cardBg,
    this.numberColor = offWhite,
    this.labelStyle,
  });

  final DateTime targetDateTime;
  final VoidCallback? onComplete;
  final Color boxColor;
  final Color numberColor;
  final TextStyle? labelStyle;

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final diff = widget.targetDateTime.difference(now);
    if (!mounted) return;
    if (diff <= Duration.zero) {
      setState(() {
        _remaining = Duration.zero;
        _completed = true;
      });
      _timer?.cancel();
      widget.onComplete?.call();
      return;
    }
    setState(() => _remaining = diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return Pulse(
        infinite: true,
        duration: const Duration(milliseconds: 900),
        child: Text(
          '¡Tiempo!',
          style: titleBold(22, color: accentGold),
          textAlign: TextAlign.center,
        ),
      );
    }
    final d = _remaining.inDays;
    final h = _remaining.inHours.remainder(24);
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    final label = widget.labelStyle ?? bodyText(11, color: softGray);

    return Row(
      children: [
        _box('$d', 'DD', label),
        const SizedBox(width: 8),
        _box(_two(h), 'HH', label),
        const SizedBox(width: 8),
        _box(_two(m), 'MM', label),
        const SizedBox(width: 8),
        _box(_two(s), 'SS', label),
      ],
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Expanded _box(String value, String hint, TextStyle label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: widget.boxColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentGold.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: titleBold(20, color: widget.numberColor),
            ),
            const SizedBox(height: 4),
            Text(hint, style: label),
          ],
        ),
      ),
    );
  }
}
