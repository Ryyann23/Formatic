import 'package:flutter/material.dart';
import 'package:formatic/features/assistant/pages/assistant_page.dart';
import 'package:formatic/features/flashcards/pages/flashcard_page.dart';
import 'package:formatic/features/home/widgets/app_bottom_nav_bar.dart';
import 'package:formatic/features/home/widgets/app_top_nav_bar.dart';
import 'package:formatic/features/library/pages/library_page.dart';
import 'package:formatic/features/profile/pages/profile_page.dart';
import 'package:formatic/features/tasks/pages/task_manager_page.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Home is the center

  static const List<String> _titles = [
    'Tarefas',
    'Flashcards',
    'Home',
    'Assistente',
    'Bibliotecas',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopNavBar(
        title: _titles[_selectedIndex],
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
        onProfileTap: _openProfile,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TaskManagerPage(isDarkMode: widget.isDarkMode),
          FlashcardPage(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
          const Center(child: Text('Home')),
          AssistantPage(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
          LibraryPage(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
