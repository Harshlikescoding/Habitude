import 'package:flutter/material.dart';
import 'todo_page.dart';
import 'notes_page.dart';
import 'routine_page.dart';
import 'summary_page.dart';
import 'habits.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MainNavigation(),
  ));
}





class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; 

  final List<Widget> _pages = [
    const NotesPage(),
    const HabitPage(),
    const ToDoPage(),
    const RoutinePage(),
    const SummaryPage(),
  ];

  final List<String> _titles = [
    'Sticky Notes',
    'Habits',
    'To-Do Today',
    'My Routine',
    'Summary',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.teal,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: "Notes",
          ),
          BottomNavigationBarItem(
             icon: Icon(Icons.track_changes),
            label: "Habits", // 👈 New
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Today",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: "Routine",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Summary",
          ),
        ],
      ),
    );
  }
}
