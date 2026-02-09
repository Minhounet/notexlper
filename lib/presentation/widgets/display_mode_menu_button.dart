import 'package:flutter/material.dart';

import '../models/display_mode.dart';

/// A popup menu button in the app bar that lets the user switch
/// between display modes (flat / grouped by category) and toggle
/// the "Checked at bottom" option.
class DisplayModeMenuButton extends StatelessWidget {
  final ChecklistDisplayMode displayMode;
  final bool checkedAtBottom;
  final ValueChanged<ChecklistDisplayMode> onDisplayModeChanged;
  final ValueChanged<bool> onCheckedAtBottomChanged;

  const DisplayModeMenuButton({
    super.key,
    required this.displayMode,
    required this.checkedAtBottom,
    required this.onDisplayModeChanged,
    required this.onCheckedAtBottomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.view_list),
      tooltip: 'Display mode',
      onSelected: (value) {
        switch (value) {
          case 'flat':
            onDisplayModeChanged(ChecklistDisplayMode.flat);
          case 'grouped':
            onDisplayModeChanged(ChecklistDisplayMode.groupedByCategory);
          case 'checked_bottom':
            onCheckedAtBottomChanged(!checkedAtBottom);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'flat',
          child: _buildMenuItem(
            context,
            icon: Icons.list,
            label: 'Flat view',
            isSelected: displayMode == ChecklistDisplayMode.flat,
          ),
        ),
        PopupMenuItem(
          value: 'grouped',
          child: _buildMenuItem(
            context,
            icon: Icons.category,
            label: 'Group by category',
            isSelected: displayMode == ChecklistDisplayMode.groupedByCategory,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'checked_bottom',
          child: _buildMenuItem(
            context,
            icon: Icons.vertical_align_bottom,
            label: 'Checked at bottom',
            isSelected: checkedAtBottom,
          ),
        ),
      ],
    );
  }

  static Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : null;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
        if (isSelected)
          Icon(Icons.check, color: color, size: 18),
      ],
    );
  }
}
