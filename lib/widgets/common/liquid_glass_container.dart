import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double opacity;
  final Color? borderColor;
  final Color color;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 30.0,
    this.blurSigma = 40.0,
    this.padding,
    this.margin,
    this.onTap,
    this.opacity = 0.1,
    this.borderColor,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: borderColor ?? Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
        ],
      ),
      child: child,
    );

    // Apply interaction if onTap is provided
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );
  }
}
