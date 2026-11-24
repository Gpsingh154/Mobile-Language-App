import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../utils/theme.dart';

/// An accessible, prominent dropdown selector widget for language switching.
/// Displays native script alongside the English label with large touch targets.
class LanguageDropdownWidget extends StatelessWidget {
  const LanguageDropdownWidget({
    super.key,
    required this.label,
    required this.selectedLanguage,
    required this.onChanged,
    required this.accentColor,
    this.isInput = true,
  });

  final String label;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppLanguage> onChanged;
  final Color accentColor;
  final bool isInput;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small uppercase header label
          Row(
            children: [
              Icon(
                isInput ? Icons.mic_rounded : Icons.volume_up_rounded,
                size: 13,
                color: accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Large accessible DropdownButton
          DropdownButtonHideUnderline(
            child: DropdownButton<AppLanguage>(
              value: selectedLanguage,
              isExpanded: true,
              isDense: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: accentColor,
                size: 22,
              ),
              dropdownColor: const Color(0xFF161E29),
              borderRadius: BorderRadius.circular(16),
              elevation: 12,
              items: AppLanguage.values.map((lang) {
                final isSelected = lang == selectedLanguage;
                return DropdownMenuItem<AppLanguage>(
                  value: lang,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lang.code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? accentColor : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lang.nativeName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              lang.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? accentColor.withOpacity(0.9)
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (lang) {
                if (lang != null) onChanged(lang);
              },
            ),
          ),
        ],
      ),
    );
  }
}
