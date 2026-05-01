import 'package:flutter/material.dart';
import '../core/theme.dart';

class EnterpriseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final Color? color;
  final VoidCallback? onTap;

  const EnterpriseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.width,
    this.height,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        boxShadow: AppTheme.softShadows,
        border: Border.all(color: AppTheme.dividerColor, width: 0.5),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }
    return cardContent;
  }
}
