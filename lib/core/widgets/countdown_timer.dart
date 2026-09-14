import 'dart:async';

import 'package:flutter/material.dart';

/// Countdown live verso [target]. Si aggiorna ogni secondo; una volta
/// superato [target] mostra [expiredLabel] invece di un tempo negativo.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.target,
    required this.style,
    this.expiredLabel = 'Chiuso',
  });

  final DateTime target;
  final TextStyle? style;
  final String expiredLabel;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.target.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = widget.target.difference(DateTime.now());
      setState(() => _remaining = next);
      if (next.isNegative) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) {
      return Text(widget.expiredLabel, style: widget.style);
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final label = days > 0
        ? '${days}g ${hours}h ${minutes}m'
        : '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}';

    return Text(label, style: widget.style);
  }
}
