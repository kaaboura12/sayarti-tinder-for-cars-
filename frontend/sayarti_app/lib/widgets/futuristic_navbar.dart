import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';

class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

class FuturisticNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final List<NavItem> items;

  const FuturisticNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      margin: const EdgeInsets.all(20),
      height: 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: isDarkMode 
          ? AppTheme.darkSurfaceColor.withOpacity(0.8)
          : Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;
              
              return _buildNavItem(
                context, 
                index, 
                item, 
                isSelected,
                isDarkMode,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, 
    int index, 
    NavItem item, 
    bool isSelected,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? (isDarkMode ? AppTheme.primaryDarkColor : AppTheme.primaryColor)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected 
                ? Colors.white 
                : isDarkMode
                  ? AppTheme.darkTextLightColor
                  : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected 
                  ? Colors.white 
                  : isDarkMode
                    ? AppTheme.darkTextLightColor
                    : Colors.grey[600],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 