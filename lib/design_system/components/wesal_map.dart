import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

/// Map abstraction.
///
/// INTEGRATION POINT (spec §4, §14): the real implementation will render
/// `google_maps_flutter` (or the chosen maps SDK) with live markers and smooth
/// driver-marker interpolation. It is deliberately NOT wired here because:
///   1. The maps SDK requires platform API keys that must be configured in the
///      native projects (restricted by bundle id), not committed to the repo.
///   2. The app must run and be reviewable before those keys exist.
///
/// This placeholder renders a styled map stand-in plus any marker labels, so
/// screens can be built and laid out now. Swapping to the real map is a change
/// inside THIS widget only — no screen needs to change (spec §2).
class WesalMap extends StatelessWidget {
  const WesalMap({
    super.key,
    this.pickupLabel,
    this.destinationLabel,
    this.showDriver = false,
    this.overlay,
  });

  final String? pickupLabel;
  final String? destinationLabel;
  final bool showDriver;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder map canvas.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surfaceContainerHighest,
                scheme.surface,
              ],
            ),
          ),
          child: CustomPaint(painter: _GridPainter(scheme.outline)),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: scheme.outline, size: 40),
              const SizedBox(height: WesalSpacing.sm),
              Text(
                'Map',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.outline),
              ),
            ],
          ),
        ),
        if (pickupLabel != null)
          Positioned(
            top: WesalSpacing.huge,
            left: WesalSpacing.xl,
            child: _Marker(
              color: WesalColors.brand,
              foreground: WesalColors.ink,
              icon: Icons.my_location,
              label: pickupLabel!,
            ),
          ),
        if (destinationLabel != null)
          Positioned(
            bottom: WesalSpacing.huge * 2,
            right: WesalSpacing.xl,
            child: _Marker(
              color: WesalColors.ink,
              icon: Icons.location_on,
              label: destinationLabel!,
            ),
          ),
        if (showDriver)
          const Positioned(
            bottom: WesalSpacing.huge * 3,
            left: WesalSpacing.huge,
            child: _Marker(
              color: WesalColors.info,
              icon: Icons.local_taxi,
              label: 'Driver',
            ),
          ),
        if (overlay != null) overlay!,
      ],
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.color,
    required this.icon,
    required this.label,
    this.foreground = Colors.white,
  });
  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(WesalRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}
