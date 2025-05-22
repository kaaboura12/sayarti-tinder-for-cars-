import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../screens/favorites_screen.dart';

class FavoriteIcon extends StatelessWidget {
  const FavoriteIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.favorite_rounded,
            size: 26,
            color: isDarkMode ? Colors.white : AppTheme.primaryColor,
          ),
          onPressed: () => _navigateToFavorites(context),
        ),
      ],
    );
  }

  void _navigateToFavorites(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FavoritesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
} 