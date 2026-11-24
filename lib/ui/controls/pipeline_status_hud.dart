import 'package:flutter/material.dart';
import '../../services/model_lifecycle_manager.dart';
import '../../state/app_state_controller.dart';
import '../../utils/theme.dart';

/// Real-time HUD widget exposing the Model Lifecycle Manager telemetry,
/// memory allocation against the strict 700MB limit, active engine badge,
/// and the primary "Try It" interactive pipeline trigger button.
class PipelineStatusHud extends StatelessWidget {
  const PipelineStatusHud({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final telemetry = controller.lifecycleManager.currentTelemetry;
    final isRunning = controller.lifecycleManager.isRunning;
    final mode = controller.currentMode;
    final accent = mode.accentColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEB111823),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRunning ? accent : Colors.white.withOpacity(0.12),
          width: isRunning ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (isRunning)
            BoxShadow(
              color: accent.withOpacity(0.15),
              blurRadius: 16,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Memory Cap Meter + Active Engine Badge + "Try It" Button
          Row(
            children: [
              // Memory Gauge & Engine Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Live pulsating status dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isRunning ? accent : Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isRunning ? accent : Colors.greenAccent).withOpacity(0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Engine Name
                        Text(
                          _getEngineLabel(telemetry.activeEngine),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isRunning ? accent : Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // RAM Usage vs 700MB Cap
                        Text(
                          '${telemetry.currentEstimatedRamMb} MB / ${telemetry.memoryCapMb} MB',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: telemetry.memoryUsageRatio > 0.85
                                ? Colors.redAccent
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Progress Bar of RAM against strict 700MB ceiling
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: telemetry.memoryUsageRatio,
                        minHeight: 4,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          telemetry.memoryUsageRatio > 0.85
                              ? Colors.redAccent
                              : (isRunning ? accent : AppTheme.learningEmerald),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Hardware Delegate Info (e.g. Windows x86_64 DirectML / XNNPACK)
                    Row(
                      children: [
                        Icon(
                          Icons.developer_board_rounded,
                          size: 11,
                          color: AppTheme.hudCyan.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            telemetry.hardwareDelegate,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: Colors.white.withOpacity(0.65),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (telemetry.isVisionPipelineLocked) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.amber.withOpacity(0.5), width: 0.8),
                            ),
                            child: const Text(
                              'VISION LOCKED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Prominent "Try It" Action Button
              ElevatedButton.icon(
                onPressed: isRunning
                    ? null
                    : () {
                        controller.triggerLiveInferencePipeline();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: accent.withOpacity(0.3),
                  elevation: isRunning ? 0 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: isRunning
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  isRunning ? 'Running' : 'Try it',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          // Live Pipeline Execution Telemetry Details (When active)
          if (isRunning || telemetry.stage == ModelStage.completed) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStageIcon(telemetry.stage),
                        size: 13,
                        color: accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          telemetry.statusMessage,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (telemetry.transcribedText != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'ASR: "${telemetry.transcribedText}"',
                      style: const TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.hudCyan,
                      ),
                    ),
                  ],
                  if (telemetry.activeModelPath != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 10,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Target: ${telemetry.activeModelPath}',
                            style: TextStyle(
                              fontSize: 9,
                              fontFamily: 'monospace',
                              color: Colors.white.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getEngineLabel(ModelEngineType engine) {
    switch (engine) {
      case ModelEngineType.none:
        return 'STANDBY (Idle)';
      case ModelEngineType.asrIndicConformer:
        return 'ASR: IndicConformer';
      case ModelEngineType.mainBrainGemma:
        return 'BRAIN: Gemma 4 E2B';
      case ModelEngineType.ttsSooktam2:
        return 'TTS: Sooktam-2';
    }
  }

  IconData _getStageIcon(ModelStage stage) {
    switch (stage) {
      case ModelStage.idle:
        return Icons.bedtime_outlined;
      case ModelStage.asrLoading:
      case ModelStage.asrListening:
        return Icons.mic_rounded;
      case ModelStage.asrReleasing:
        return Icons.cleaning_services_rounded;
      case ModelStage.gemmaLoading:
      case ModelStage.gemmaReasoning:
        return Icons.psychology_rounded;
      case ModelStage.gemmaReleasing:
        return Icons.memory_rounded;
      case ModelStage.ttsLoading:
      case ModelStage.ttsSynthesizing:
        return Icons.volume_up_rounded;
      case ModelStage.ttsReleasing:
        return Icons.check_circle_outline_rounded;
      case ModelStage.completed:
        return Icons.check_circle_rounded;
      case ModelStage.error:
        return Icons.error_outline_rounded;
    }
  }
}
