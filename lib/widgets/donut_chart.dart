import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutChart extends StatefulWidget {
  const DonutChart({super.key, required this.values});
  final Map<String, double> values;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.values.entries.where((e) => e.value > 0).toList();
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    if (total <= 0) {
      return const SizedBox(
        height: 190,
        child: Center(child: Text('Chưa có dữ liệu chi tiêu')),
      );
    }
    final colors = _chartColors(context);
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _DonutPainter(
                values: entries.map((e) => e.value).toList(),
                colors: colors,
                progress: Curves.easeOutCubic.transform(_controller.value),
                centerText: total.toStringAsFixed(0),
                textColor: Theme.of(context).colorScheme.onSurface,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < entries.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(
                    color: colors[i % colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('${entries[i].key} (${(entries[i].value / total * 100).round()}%)'),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

List<Color> _chartColors(BuildContext context) => [
  Theme.of(context).colorScheme.primary,
  Theme.of(context).colorScheme.tertiary,
  Colors.orange,
  Colors.purple,
  Colors.green,
  Colors.blue,
  Colors.pink,
];

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.progress,
    required this.centerText,
    required this.textColor,
  });

  final List<double> values;
  final List<Color> colors;
  final double progress;
  final String centerText;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.30
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * math.pi * 2 * progress;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += (values[i] / total) * math.pi * 2;
    }
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textColor),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: radius * 1.6);
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.values != values ||
      oldDelegate.centerText != centerText;
}
