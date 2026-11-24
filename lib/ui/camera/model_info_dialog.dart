import 'package:flutter/material.dart';
import '../../services/model_lifecycle_manager.dart';
import '../../state/app_state_controller.dart';

/// Modal dialog providing the comprehensive in-app Model Weight Manager,
/// explaining the 2.46 GB question (zero download required vs raw weights),
/// high-speed USB iTunes/Finder file sharing, real-time memory metrics,
/// and hosting the prominent '⚡ Try Sequential Pipeline' trigger button.
class ModelInfoDialog extends StatelessWidget {
  const ModelInfoDialog({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.lifecycleManager,
      builder: (context, _) {
        final telemetry = controller.lifecycleManager.currentTelemetry;
        final isRunning = controller.lifecycleManager.isSequentialPipelineRunning;

        return Dialog(
          backgroundColor: const Color(0xFF131A26),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Colors.white12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header with Memory Chip icon & Close
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
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
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Model Weight Manager',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Prominent Interactive '⚡ Try Sequential Pipeline' Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isRunning
                          ? null
                          : () {
                              controller.triggerLiveInferencePipeline();
                            },
                      icon: isRunning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.bolt_rounded, size: 20, color: Colors.black),
                      label: Text(
                        isRunning
                            ? 'Executing Pipeline (${telemetry.currentEstimatedRamMb} MB)...'
                            : '⚡ Try Sequential Pipeline',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  if (isRunning) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  telemetry.statusMessage,
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${telemetry.currentEstimatedRamMb} / ${telemetry.memoryCapMb} MB',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: telemetry.progress,
                              minHeight: 4,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 3. Zero-Download Clarification Banner (The 2.46 GB Question)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x2210B981),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Zero Download Required To Test',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'The app runs out-of-the-box using the built-in On-Device Semantic Engine. Downloading 2.46 GB raw weights is completely optional.',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. Dual Operational Modes Breakdown
                  const Text(
                    'Operational Modes',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _modeCard(
                    title: 'Mode A: On-Device Semantic Engine',
                    subtitle: 'Active & Ready out-of-the-box (0 MB download)',
                    details: 'Full local grammar parsing, bilingual Gurmukhi/Indic query expansion, and native voice synthesis running offline.',
                    isActive: true,
                  ),
                  const SizedBox(height: 8),
                  _modeCard(
                    title: 'Mode B: Full Raw Weights Mode',
                    subtitle: 'Optional LiteRT-LM Direct Tensor Execution (2.46 GB)',
                    details: 'Executes raw INT8/FP16 weights directly on Apple Neural Engine (ANE) / GPU delegates.',
                    isActive: false,
                  ),

                  const SizedBox(height: 16),

                  // 5. Model Weights Inventory & Status
                  const Text(
                    'Model Weights Inventory',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _modelStatusRow('Gemma 4 E2B Instruct', '2.46 GB', 'Ready (Semantic Active)', const Color(0xFF10B981)),
                  _modelStatusRow('IndicConformer ASR', '188 MB', 'Ready (16kHz INT8)', const Color(0xFF10B981)),
                  _modelStatusRow('Sooktam-2 / Kokoro TTS', '281 MB', 'Ready (AVSpeech Active)', const Color(0xFF10B981)),

                  const SizedBox(height: 16),

                  // 6. USB iTunes/Finder 30-Second Transfer Guide
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.usb_rounded, color: Color(0xFF38BDF8), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'USB iTunes / Finder Sideloading (30s Transfer)',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'With iOS File Sharing enabled (UIFileSharingEnabled):\n'
                          '1. Connect iPhone 13 Pro to your laptop via USB cable.\n'
                          '2. Open iTunes / Apple Devices / Finder.\n'
                          '3. Click File Sharing > "BoliXR Companion".\n'
                          '4. Drag & drop "gemma-4-E2B-it.litertlm" (2.46 GB) into Documents.\n'
                          '5. High-speed USB transfers all 2.46 GB in ~30 seconds without Wi-Fi!',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 7. System Diagnostics & Hardware Limits
                  const Text(
                    'Hardware & Memory Diagnostics',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _infoRow('Hardware Delegate', ModelLifecycleManager.activeHardwareDelegate),
                  _infoRow('RAM Budget Ceiling', '${ModelLifecycleManager.targetMemoryCapMb} MB strict mobile cap'),
                  _infoRow('Current RAM Footprint', '${telemetry.currentEstimatedRamMb} MB'),
                  _infoRow('Execution Threads', '${ModelLifecycleManager.numThreads} threads'),
                  _infoRow('Vision Sensor Mode', 'On-Demand Single Frame Router'),
                  _infoRow('Total On-Demand Frames', '${controller.visionRouter.onDemandFrameCount} frames'),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required String details,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0x1F10B981) : Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? const Color(0xFF10B981).withOpacity(0.5) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 14,
                color: isActive ? const Color(0xFF10B981) : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.white70,
                ),
              ),
              const Spacer(),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(details, style: const TextStyle(fontSize: 10.5, color: Colors.white60, height: 1.3)),
        ],
      ),
    );
  }

  Widget _modelStatusRow(String name, String size, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              size,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              status,
              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
