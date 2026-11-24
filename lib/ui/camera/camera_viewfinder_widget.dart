import 'package:flutter/material.dart';
import '../../state/app_state_controller.dart';
import '../../utils/theme.dart';
import 'scan_reticle_painter.dart';

/// Interactive camera viewfinder widget that renders live HUD markers,
/// real-time detection bounding boxes, and object selection handles.
class CameraViewfinderWidget extends StatefulWidget {
  const CameraViewfinderWidget({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  @override
  State<CameraViewfinderWidget> createState() => _CameraViewfinderWidgetState();
}

class _CameraViewfinderWidgetState extends State<CameraViewfinderWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.controller.currentMode;
    final accent = mode.accentColor;
    final activeEntity = widget.controller.activeEntity;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Camera Viewport Background (Deep cinematic camera simulator)
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF1E2837),
                Color(0xFF0F151F),
                Color(0xFF070A0F),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Simulated realistic object silhouette in focus
              Center(
                child: Opacity(
                  opacity: 0.15,
                  child: Icon(
                    Icons.filter_vintage_rounded,
                    size: 220,
                    color: accent,
                  ),
                ),
              ),
              // Lens focal grid lines
              CustomPaint(
                painter: _LensGridPainter(),
              ),
            ],
          ),
        ),

        // 2. Animated HUD Reticle & Bounding Boxes
        AnimatedBuilder(
          animation: _scanAnimationController,
          builder: (context, _) {
            return CustomPaint(
              painter: ScanReticlePainter(
                activeEntity: activeEntity,
                allEntities: widget.controller.detectedEntities,
                scanProgress: _scanAnimationController.value,
                accentColor: accent,
                isScanning: widget.controller.isScanning,
              ),
            );
          },
        ),

        // 3. Floating HUD Metadata Overlay (Target Info Tag)
        if (activeEntity != null)
          Positioned(
            top: MediaQuery.of(context).size.height * activeEntity.boundingBox.top - 28,
            left: MediaQuery.of(context).size.width * activeEntity.boundingBox.left + 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  activeEntity.getTerm(widget.controller.inputLanguage),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(activeEntity.confidence * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 4. Quick Lens Floating Action Controls (Right side HUD)
        Positioned(
          right: 16,
          top: 140,
          child: Column(
            children: [
              // Scanner Pause/Play Toggle
              _HudCircleButton(
                icon: widget.controller.isScanning
                    ? Icons.sensors_rounded
                    : Icons.sensors_off_rounded,
                tooltip: widget.controller.isScanning ? 'Scanner Active' : 'Scanner Paused',
                isActive: widget.controller.isScanning,
                accentColor: accent,
                onTap: widget.controller.toggleScanning,
              ),
              const SizedBox(height: 12),
              // Cycle Detected Target Object
              _HudCircleButton(
                icon: Icons.track_changes_rounded,
                tooltip: 'Next Target Object',
                isActive: true,
                accentColor: accent,
                onTap: widget.controller.cycleNextEntity,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HudCircleButton extends StatelessWidget {
  const _HudCircleButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xCC111827),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? accentColor.withOpacity(0.7) : Colors.white24,
                width: 1.5,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 8,
                  ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? accentColor : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _LensGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    // Rule of thirds grid lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
