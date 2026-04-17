import 'package:flutter/material.dart';
import '../core/theme.dart';

enum BadgeType { success, warning, error, neutral, primary }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = BadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (type) {
      case BadgeType.success:
        backgroundColor = AppTheme.success.withValues(alpha: 0.1);
        textColor = AppTheme.success;
        break;
      case BadgeType.warning:
        backgroundColor = AppTheme.warning.withValues(alpha: 0.1);
        textColor = AppTheme.warning;
        break;
      case BadgeType.error:
        backgroundColor = AppTheme.error.withValues(alpha: 0.1);
        textColor = AppTheme.error;
        break;
      case BadgeType.primary:
        backgroundColor = AppTheme.primaryNavy.withValues(alpha: 0.1);
        textColor = AppTheme.primaryNavy;
        break;
      case BadgeType.neutral:
        backgroundColor = AppTheme.dividerColor.withValues(alpha: 0.3);
        textColor = AppTheme.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.0), // Pill shape
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
