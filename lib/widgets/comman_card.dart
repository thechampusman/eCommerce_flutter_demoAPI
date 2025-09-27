import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CommanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double elevation;
  final Color? backgroundColor;

  const CommanCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.elevation = 1,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: elevation * 2,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
