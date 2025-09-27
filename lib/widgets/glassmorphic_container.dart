import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.border,
    this.width,
    this.height,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    
    
    
    final double effectiveOpacity = isLight
        ? math.min(0.9, 0.18 + opacity) 
        : opacity;

    final Color fillColor = Colors.white.withOpacity(effectiveOpacity);

    final BoxBorder effectiveBorder =
        border ??
        Border.all(
          color: isLight
              ? Colors.black.withOpacity(0.06)
              : Colors.white.withOpacity(0.18),
          width: 1.0,
        );

    final List<BoxShadow>? boxShadow = isLight
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ]
        : null;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor,
              gradient: isLight
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(effectiveOpacity * 1.05),
                        Colors.white.withOpacity(
                          math.max(0.02, effectiveOpacity * 0.6),
                        ),
                      ],
                    )
                  : null,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: effectiveBorder,
              boxShadow: boxShadow,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
