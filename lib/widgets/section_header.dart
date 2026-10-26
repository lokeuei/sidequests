import 'package:flutter/material.dart';

/// Editorial section header: serif title with an optional trailing note.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(title, style: text.titleLarge)),
        if (note != null)
          Text(
            note!,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
      ],
    );
  }
}
