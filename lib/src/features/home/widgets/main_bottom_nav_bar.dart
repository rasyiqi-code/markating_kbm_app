import 'package:flutter/material.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';

class MainBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final bool isAdmin;
  final Function(int) onTap;

  const MainBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. Home
            Expanded(
              child: _buildNavItem(
                context,
                0,
                Icons.home_rounded,
                Icons.home_outlined,
              ),
            ),

            // 2. Bio
            Expanded(
              child: _buildNavItem(context, 1, Icons.link_rounded, Icons.link),
            ),

            // 3. Gap for FAB
            const SizedBox(width: 48),

            // 4. Catalog / Manage Catalog
            Expanded(
              child: _buildNavItem(
                context,
                2,
                isAdmin ? Icons.edit_note_rounded : Icons.menu_book_rounded,
                isAdmin ? Icons.edit_note_outlined : Icons.menu_book_outlined,
              ),
            ),

            // 5. Profile
            Expanded(
              child: _buildNavItem(
                context,
                3,
                Icons.person_rounded,
                Icons.person_outline_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        width: 50,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: isSelected
                ? AppTheme.primaryColor
                : Theme.of(context).unselectedWidgetColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}
