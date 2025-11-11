import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fontSize = 12;
    if (width < 350) {
      fontSize = 9;
    } else if (width < 400) {
      fontSize = 10;
    }
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Tarefas'),
        BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Flashcards'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'Assistente',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book),
          label: 'Bibliotecas',
        ),
      ],
    );
  }
}
