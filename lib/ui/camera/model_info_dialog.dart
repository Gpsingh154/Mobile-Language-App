import 'package:flutter/material.dart';
import '../../services/model_lifecycle_manager.dart';
import '../../state/app_state_controller.dart';

class ModelInfoDialog extends StatelessWidget {
  const ModelInfoDialog({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final telemetry = controller.lifecycleManager.currentTelemetry;

    return Dialog(
      backgroundColor: const Color(0xFF131A26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0x3310B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.memory_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Gemma-4-E2B-it Engine',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Model Format', 'LiteRT-LM Mixed INT8/FP16 (assets/models/gemma)'),
            _infoRow('ASR Acoustic Model', 'indic_conformer_int8.onnx (16kHz Mono)'),
            _infoRow('TTS Engine', 'Sooktam-2 / Kokoro (assets/models/tts)'),
            _infoRow('Hardware Delegate', ModelLifecycleManager.activeHardwareDelegate),
            _infoRow('RAM Budget Ceiling', '${ModelLifecycleManager.targetMemoryCapMb} MB strict mobile cap'),
            _infoRow('Current Estimated RAM', '${telemetry.currentEstimatedRamMb} MB'),
            _infoRow('Execution Threads', '${ModelLifecycleManager.numThreads} threads'),
            _infoRow('Vision Mode', 'On-Demand Single Frame Router (Continuous AI decoupled)'),
            _infoRow('Total On-Demand Frames', '${controller.visionRouter.onDemandFrameCount} frames'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
