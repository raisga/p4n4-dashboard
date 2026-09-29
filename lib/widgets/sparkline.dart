import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Single-series area sparkline with a hover/tap crosshair readout.
class Sparkline extends StatefulWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.format,
    this.color,
    this.maxY,
    this.capacity = 60,
    this.height = 64,
  });

  final List<double> values;
  final String Function(double) format;

  /// Line colour; defaults to the theme accent.
  final Color? color;

  /// Fixed ceiling (e.g. 100 for percentages); otherwise auto-scaled.
  final double? maxY;

  /// Number of slots on the x-axis, so the line fills in from the right.
  final int capacity;
  final double height;

  @override
  State<Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<Sparkline> {
  int? _hover;

  P4Colors get p4 => context.p4;

  void _track(Offset pos, double width) {
    final n = widget.values.length;
    if (n == 0) return;
    final step = width / (widget.capacity - 1);
    final slot = (pos.dx / step).round();
    final i = slot - (widget.capacity - n);
    setState(() => _hover = i.clamp(0, n - 1));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return MouseRegion(
          onHover: (e) => _track(e.localPosition, w),
          onExit: (_) => setState(() => _hover = null),
          child: GestureDetector(
            onPanDown: (d) => _track(d.localPosition, w),
            onPanUpdate: (d) => _track(d.localPosition, w),
            onPanEnd: (_) => setState(() => _hover = null),
            onPanCancel: () => setState(() => _hover = null),
            child: SizedBox(
              height: widget.height,
              width: w,
              child: CustomPaint(
                painter: _SparkPainter(
                  widget.values,
                  widget.color ?? p4.accent,
                  p4,
                  widget.maxY,
                  widget.capacity,
                  _hover,
                ),
                child: _hover == null || _hover! >= widget.values.length
                    ? null
                    : Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: p4.bg3,
                          child: Text(
                            '${widget.format(widget.values[_hover!])}  '
                            '−${(widget.values.length - 1 - _hover!) * 2}s',
                            style: p4.mono(size: 10, color: p4.text),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.p4, this.maxY, this.capacity, this.hover);

  final List<double> values;
  final Color color;
  final P4Colors p4;
  final double? maxY;
  final int capacity;
  final int? hover;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = p4.border2
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;

    final top = maxY ?? (values.reduce(math.max) * 1.2).clamp(1e-6, double.infinity);
    final step = size.width / (capacity - 1);
    final offset = capacity - values.length;
    Offset pt(int i) => Offset((i + offset) * step, size.height - (values[i] / top).clamp(0, 1) * size.height);

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(pt(i).dx, pt(i).dy);
    }
    final area = Path.from(line)
      ..lineTo(pt(values.length - 1).dx, size.height)
      ..lineTo(pt(0).dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    final mark = hover ?? values.length - 1;
    final p = pt(mark);
    if (hover != null) {
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), Paint()..color = p4.muted.withValues(alpha: 0.5));
    }
    canvas.drawCircle(p, 5, Paint()..color = p4.bg2);
    canvas.drawCircle(p, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}
