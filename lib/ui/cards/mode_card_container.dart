import 'package:flutter/material.dart';
import '../../models/app_mode.dart';
import '../../state/app_state_controller.dart';
import 'exploration_card_widget.dart';
import 'learning_card_widget.dart';

/// Container that observes state changes and smoothly transitions between
/// Exploration Mode card and Learning Mode card based on the active language configuration.
class ModeCardContainer extends StatelessWidget {
  const ModeCardContainer({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final activeEntity = controller.activeEntity;
    if (activeEntity == null) {
      return const SizedBox.shrink();
    }

    final mode = controller.currentMode;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: mode == AppMode.exploration
          ? ExplorationCardWidget(
              key: ValueKey('exploration_${controller.inputLanguage.code}_${activeEntity.id}'),
              entity: activeEntity,
              language: controller.inputLanguage,
              controller: controller,
            )
          : LearningCardWidget(
              key: ValueKey('learning_${controller.inputLanguage.code}_${controller.outputLanguage.code}_${activeEntity.id}'),
              entity: activeEntity,
              sourceLanguage: controller.inputLanguage,
              targetLanguage: controller.outputLanguage,
              controller: controller,
            ),
    );
  }
}
