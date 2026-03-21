import 'dart:async';

import 'package:flutter/material.dart';

/// Número que sube en pasos suaves simulando rendimiento (cada [tickSeconds]).
class YieldCounterWidget extends StatefulWidget {
  const YieldCounterWidget({
    super.key,
    required this.initialValue,
    required this.incrementPerTick,
    required this.textStyle,
    this.tickSeconds = 10,
    this.format = _defaultFormat,
  });

  final double initialValue;
  final double incrementPerTick;
  final TextStyle textStyle;
  final int tickSeconds;
  final String Function(double v) format;

  static String _defaultFormat(double v) => v.toStringAsFixed(2);

  @override
  State<YieldCounterWidget> createState() => _YieldCounterWidgetState();
}

class _YieldCounterWidgetState extends State<YieldCounterWidget> {
  late double _value;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _timer = Timer.periodic(Duration(seconds: widget.tickSeconds), (_) {
      if (!mounted) return;
      setState(() => _value += widget.incrementPerTick);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: Text(
        widget.format(_value),
        key: ValueKey(_value.toStringAsFixed(4)),
        style: widget.textStyle,
      ),
    );
  }
}
