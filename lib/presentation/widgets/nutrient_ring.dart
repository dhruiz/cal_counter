import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/styles.dart';

/// Anillo de progreso para un nutriente: muestra gráficamente el porcentaje
/// consumido respecto al objetivo diario, junto con consumido/objetivo y
/// restante en valores absolutos. Si se supera el objetivo, el tramo
/// excedente se sobreescribe en rojo sobre el anillo.
class NutrientRing extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final String unit;
  final Color color;

  const NutrientRing({
    super.key,
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = target > 0 ? consumed / target : 0;
    final double remaining = target - consumed;
    final bool over = remaining < 0;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingSmall),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppStyles.paddingSmall),
            AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: progress,
                  color: color,
                  trackColor: color.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    target > 0 ? '${(progress * 100).round()}%' : '—',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: over ? AppStyles.ringOver : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppStyles.paddingSmall),
            Text(
              '${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
              style: textTheme.bodySmall,
            ),
            Text(
              over
                  ? 'Exceso: ${(-remaining).toStringAsFixed(0)} $unit'
                  : 'Restante: ${remaining.toStringAsFixed(0)} $unit',
              style: textTheme.bodySmall?.copyWith(
                color: over ? AppStyles.ringOver : null,
                fontWeight: over ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.shortestSide * 0.12;
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - stroke) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Pista de fondo (lo restante)
    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    const double startAngle = -math.pi / 2; // arranca arriba (12 en punto)

    // Tramo consumido (hasta el 100 %)
    final double baseSweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (baseSweep > 0) {
      paint
        ..color = color
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, baseSweep, false, paint);
    }

    // Sobreingesta: el excedente sobreescribe el tramo correspondiente en rojo
    if (progress > 1) {
      final double overSweep = 2 * math.pi * (progress - 1).clamp(0.0, 1.0);
      paint.color = AppStyles.ringOver;
      canvas.drawArc(rect, startAngle, overSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
