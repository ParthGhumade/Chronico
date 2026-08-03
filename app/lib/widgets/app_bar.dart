import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChronicoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentTabIndex;
  final ValueChanged<int> onTabSelected;

  const ChronicoAppBar({
    super.key,
    required this.currentTabIndex,
    required this.onTabSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Container(
      color: ChronicoColors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          decoration: const BoxDecoration(
            color: ChronicoColors.surface,
            border: Border(
              bottom: BorderSide(color: ChronicoColors.surfaceContainerHighest, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Brand Title
              Row(
                children: [
                  if (isDesktop)
                    IconButton(
                      icon: const Icon(Icons.menu, color: ChronicoColors.primary),
                      onPressed: () {},
                    ),
                  const Text(
                    'Chronico',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ChronicoColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              // Desktop Navigation Links
              if (isDesktop)
                Row(
                  children: [
                    _NavButton(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Home',
                      isSelected: currentTabIndex == 0,
                      onTap: () => onTabSelected(0),
                    ),
                    const SizedBox(width: 8),
                    _NavButton(
                      icon: Icons.event_note_outlined,
                      activeIcon: Icons.event_note,
                      label: 'Events',
                      isSelected: currentTabIndex == 1,
                      onTap: () => onTabSelected(1),
                    ),
                    const SizedBox(width: 8),
                    _NavButton(
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      label: 'Settings',
                      isSelected: currentTabIndex == 2,
                      onTap: () => onTabSelected(2),
                    ),
                  ],
                ),

              // Right: Account Profile Button
              IconButton(
                icon: const Icon(Icons.account_circle, color: ChronicoColors.primary, size: 28),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: ChronicoColors.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected
                  ? ChronicoColors.onSecondaryContainer
                  : ChronicoColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? ChronicoColors.onSecondaryContainer
                    : ChronicoColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
