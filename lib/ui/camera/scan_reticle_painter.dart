import 'package:flutter/material.dart';
import '../../models/recognized_entity.dart';
import '../../utils/theme.dart';

/// Custom painter rendering the futuristic camera HUD, corner brackets,
/// target lock on detected entity, and animated scanning line.
class ScanReticlePainter extends CustomPainter {
  final RecognizedEntity? activeEntity;
  final List<RecognizedEntity> allEntities;
  final double scanProgress;
  final Color accentColor;
  final bool isScanning;

  ScanReticlePainter({
    required this.activeEntity,
    required this.allEntities,
    required this.scanProgress,
    required this.accentColor,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle background sensor grid
    _drawSensorGrid(canvas, size);

    // 2. Draw animated scanline if active
    if (isScanning) {
      _drawScanline(canvas, size);
    }

    // 3. Draw bounding box reticles for all detected entities
    for (final entity in allEntities) {
      final isSelected = entity == activeEntity;
      _drawEntityReticle(canvas, size, entity, isSelected);
    }
  }

  void _drawSensorGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.hudGrid
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw center crosshair
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      Offset(center.dx - 15, center.dy),
      Offset(center.dx + 15, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 15),
      Offset(center.dx, center.dy + 15),
      gridPaint,
    );
  }

  void _drawScanline(Canvas canvas, Size size) {
    final yPos = size.height * scanProgress;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withOpacity(0.0),
          accentColor.withOpacity(0.8),
          accentColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, yPos, size.width, 2))
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), linePaint);
  }

  void _drawEntityReticle(
    Canvas canvas,
    Size size,
    RecognizedEntity entity,
    bool isSelected,
  ) {
    final rect = Rect.fromLTWH(
      entity.boundingBox.left * size.width,
      entity.boundingBox.top * size.height,
      entity.boundingBox.width * size.width,
      entity.boundingBox.height * size.height,
    );

    final color = isSelected ? accentColor : Colors.white.withOpacity(0.4);
    final bracketLength = isSelected ? 24.0 : 16.0;

    final bracketPaint = Paint()
      ..color = color
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-Left Corner
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(bracketLength, 0), bracketPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, bracketLength), bracketPaint);

    // Top-Right Corner
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-bracketLength, 0), bracketPaint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, bracketLength), bracketPaint);

    // Bottom-Left Corner
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(bracketLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -bracketLength), bracketPaint);

    // Bottom-Right Corner
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-bracketLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -bracketLength), bracketPaint);

    // If selected, draw subtle shaded target box and confidence badge
    if (isSelected) {
      final fillPaint = Paint()
        ..color = accentColor.withOpacity(0.06)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);

      // Label background above box
      final labelBgPaint = Paint()
        ..color = const Color(0xE610141D)
        ..style = PaintingStyle.fill;

      const labelHeight = 22.0;
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top - labelHeight - 4, 130, labelHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(labelRect, labelBgPaint);

      // Border for label
      final labelBorderPaint = Paint()
        ..color = accentColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(labelRect, labelBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ScanReticlePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.activeEntity != activeEntity ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isScanning != isScanning;
  }
}
