import 'package:flutter/material.dart';
import 'package:manage_intern/screens/interns/intern_list_screen.dart';
import 'package:manage_intern/screens/mentors/mentor_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    InternListScreen(),
    MentorListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Thực tập sinh',
          ),
          NavigationDestination(
            icon: Icon(Icons.supervisor_account_outlined),
            selectedIcon: Icon(Icons.supervisor_account),
            label: 'Người hướng dẫn',
          ),
        ],
      ),
    );
  }
}

