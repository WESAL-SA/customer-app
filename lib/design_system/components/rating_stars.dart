import 'package:flutter/material.dart';

import '../colors.dart';

/// Interactive or read-only star rating. Uses an icon difference plus value so
/// status is never communicated by color alone (spec §35 accessibility).
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 40,
    this.count = 5,
  });

  /// Current rating (0..count). For read-only display pass [onChanged] as null.
  final double value;
  final ValueChanged<int>? onChanged;
  final double size;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final filled = i < value;
        final star = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? WesalColors.warning : Theme.of(context).colorScheme.outline,
        );
        if (onChanged == null) return star;
        return Semantics(
          button: true,
          label: 'Rate ${i + 1} of $count stars',
          child: IconButton(
            iconSize: size,
            onPressed: () => onChanged!(i + 1),
            icon: star,
          ),
        );
      }),
    );
  }
}
