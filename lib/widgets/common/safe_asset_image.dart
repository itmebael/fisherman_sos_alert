import 'package:flutter/material.dart';

/// A safe wrapper for Image.asset that handles missing assets gracefully
class SafeAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Color? color;

  const SafeAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // Return placeholder or a default icon if asset is missing
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: placeholder ??
              Icon(
                Icons.image_not_supported,
                size: (width != null && height != null)
                    ? (width! < height! ? width! * 0.5 : height! * 0.5)
                    : 24,
                color: Colors.grey.shade600,
              ),
        );
      },
    );
  }
}








