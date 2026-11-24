import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../models/app_mode.dart';
import '../../state/app_state_controller.dart';
import 'language_dropdown_widget.dart';

/// Prominent top control bar housing the Input and Output language dropdown selectors,
/// language swap action, and the dynamic Mode status indicator badge.
class LanguageSelectorBar extends StatelessWidget {
  const LanguageSelectorBar({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final mode = controller.currentMode;
    final accent = mode.accentColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.50),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Input Selector <-> Swap Button <-> Output Selector
            Row(
              children: [
                // Input Language Dropdown
                Expanded(
                  child: LanguageDropdownWidget(
                    label: 'Input Language',
                    selectedLanguage: controller.inputLanguage,
                    onChanged: controller.setInputLanguage,
                    accentColor: accent,
                    isInput: true,
                  ),
                ),

                // Center Swap Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: controller.swapLanguages,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2633),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withOpacity(0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: accent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Output Language Dropdown
                Expanded(
                  child: LanguageDropdownWidget(
                    label: 'Output Language',
                    selectedLanguage: controller.outputLanguage,
                    onChanged: controller.setOutputLanguage,
                    accentColor: accent,
                    isInput: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Dynamic Mode Status Banner (Exploration vs Learning)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: mode.badgeBgColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: accent.withOpacity(0.7),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode.icon,
                    size: 16,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mode.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: accent,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    mode.isExploration
                        ? '${controller.inputLanguage.nativeName} (Monolingual)'
                        : '${controller.inputLanguage.nativeName} ➔ ${controller.outputLanguage.nativeName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
