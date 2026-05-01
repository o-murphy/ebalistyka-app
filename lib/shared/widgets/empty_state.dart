import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:flutter/material.dart';

enum EmptyStateType {
  noProfile,
  noAmmo,
  noSight,
  incompleteAmmo,
  error,
  noData,
}

extension _EmptyStateTypeProps on EmptyStateType {
  IconData get icon => switch (this) {
    EmptyStateType.noProfile => Icons.military_tech_outlined,
    EmptyStateType.noAmmo => IconDef.ammo,
    EmptyStateType.noSight => IconDef.sight,
    EmptyStateType.incompleteAmmo => IconDef.ammo,
    EmptyStateType.error => Icons.error_outline,
    EmptyStateType.noData => Icons.inbox_outlined,
  };

  String get defaultMessage => switch (this) {
    EmptyStateType.noProfile => 'No profile selected',
    EmptyStateType.noAmmo => 'No ammo selected',
    EmptyStateType.noSight => 'No sight selected',
    EmptyStateType.incompleteAmmo => 'Ammo data is incomplete',
    EmptyStateType.error => 'Something went wrong',
    EmptyStateType.noData => 'No data',
  };
}

class EmptyStatePlaceholder extends StatelessWidget {
  final EmptyStateType type;
  final String? message;

  const EmptyStatePlaceholder({
    super.key,
    this.type = EmptyStateType.noData,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);
    final color = type == EmptyStateType.error ? cs.error : cs.outline;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 40, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message ?? type.defaultMessage,
            style: tt.bodyMedium?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
