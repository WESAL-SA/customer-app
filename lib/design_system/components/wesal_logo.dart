import 'package:flutter/material.dart';

import '../colors.dart';

/// The Wesal brand mark (gold pin + plane on the dark-green squircle), rendered
/// from the high-resolution icon asset so it stays crisp at any size.
///
/// Use this instead of embedding the raw image path in screens.
class WesalLogo extends StatelessWidget {
  const WesalLogo({super.key, this.size = 96, this.rounded = true});

  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/icon/wesal_icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _Fallback(size: size),
    );
    if (!rounded) return image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22), // iOS squircle-ish
      child: image,
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: WesalColors.brandInk,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(Icons.location_on, color: WesalColors.brand, size: size * 0.5),
    );
  }
}
