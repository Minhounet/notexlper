import 'package:flutter/material.dart';

/// A horizontal line with the label "Checked" in the middle.
///
/// Displayed between unchecked and checked items when the
/// "Checked at bottom" display option is enabled.
class CheckedSeparator extends StatelessWidget {
  const CheckedSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Checked',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
