import 'package:flutter/material.dart';
import 'package:formatic/features/auth/pages/login_page.dart';
import 'package:formatic/services/auth/auth_service.dart';

class AppTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final VoidCallback? onProfileTap;

  const AppTopNavBar({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.onThemeToggle,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthService().signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(onThemeToggle: onThemeToggle),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
          onPressed: onThemeToggle,
        ),
        if (onProfileTap != null)
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil',
            onPressed: onProfileTap,
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
    );
  }
}
