// =============================================================================
// FILE: lib/shared/layouts/admin_topbar.dart
// PURPOSE: Enterprise SaaS Topbar with Global Search & Profile Management
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/design_system.dart';
import '../../core/constants/app_strings.dart';
import '../../features/auth/auth_guard_provider.dart';

class AdminTopbar extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopbar({
    super.key,
    required this.onMenuPressed,
    this.showMenuButton = false,
  });

  final VoidCallback onMenuPressed;
  final bool showMenuButton;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ── Mobile/Tablet Menu Button ──────────────────────────────────────
          if (showMenuButton) ...[
            Tooltip(
              message: AppStrings.menuTooltip,
              child: IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            AppSpacing.hGapMd,
          ],

          // ── Global Search ──────────────────────────────────────────────────
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: AppStrings.searchPlatformTooltip,
                  hintStyle: AppTextStyles.body(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: scheme.primary),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          AppSpacing.hGapXl,

          // ── Actions ────────────────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification with Badge
              Stack(
                children: [
                  Tooltip(
                    message: AppStrings.notificationsTooltip,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),

              const ThemeToggleButton(),

              const VerticalDivider(width: 32, indent: 20, endIndent: 20),

              // Profile Dropdown
              _ProfileDropdown(),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      offset: const Offset(0, 8), // Small, clean 8px gap just below the profile container
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                'SA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            AppSpacing.hGapMd,
            if (ResponsiveWrapper.isDesktop(context)) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.roleSuperAdmin,
                    style: AppTextStyles.body(color: scheme.onSurface).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    AppStrings.rolePlatformOwner,
                    style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(authGuardProvider.notifier).clearSession();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18),
              AppSpacing.hGapMd,
              const Text(AppStrings.accountProfile),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 18),
              AppSpacing.hGapMd,
              const Text(AppStrings.accountSettings),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: scheme.error),
              AppSpacing.hGapMd,
              Text(AppStrings.accountLogout, style: TextStyle(color: scheme.error)),
            ],
          ),
        ),
      ],
    );
  }
}
