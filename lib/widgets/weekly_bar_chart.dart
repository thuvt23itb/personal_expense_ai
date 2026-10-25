import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({super.key, required this.values});
  final List<double> values;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 230,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _WeeklyPainter(
              values: widget.values,
              progress: Curves.easeOutCubic.transform(_controller.value),
              barColor: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onSurface,
              gridColor: Theme.of(context).dividerColor,
            ),
          ),
        ),
      );
}

class _WeeklyPainter extends CustomPainter {
  _WeeklyPainter({
    required this.values,
    required this.progress,
    required this.barColor,
    required this.textColor,
    required this.gridColor,
  });

  final List<double> values;
  final double progress;
  final Color barColor;
  final Color textColor;
  final Color gridColor;
  final labels = const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void paint(Canvas canvas, Size size) {
    const left = 12.0, right = 8.0, top = 16.0, bottom = 28.0;
    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final gridPaint = Paint()..color = gridColor.withValues(alpha: 0.5)..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + chartH * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
    }
    final slot = chartW / 7;
    final barW = slot * 0.48;
    final textStyle = TextStyle(fontSize: 11, color: textColor);
    for (var i = 0; i < 7; i++) {
      final value = i < values.length ? values[i] : 0.0;
      final barH = chartH * (value / safeMax) * progress;
      final x = left + slot * i + (slot - barW) / 2;
      final y = top + chartH - barH;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, math.max(0, barH)),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, Paint()..color = barColor);
      final label = labels[i];
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, top + chartH + 7));
      if (value > 0) {
        final amount = NumberFormat.compact().format(value);
        final valuePainter = TextPainter(
          text: TextSpan(text: amount, style: textStyle.copyWith(fontSize: 9)),
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: slot);
        valuePainter.paint(canvas, Offset(x + barW / 2 - valuePainter.width / 2, math.max(0, y - 15)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}
