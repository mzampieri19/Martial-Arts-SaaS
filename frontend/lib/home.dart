// This is the page you see after you log in /sign up. For now it will just be empty
// This page also has a navigation page at the bottom with: 
// Home page, Search/Classes, Calendar, Profile, (Place holder icons on nav bar, click to empty pages for now) 

import 'package:flutter/material.dart';
import 'profile.dart';
import 'classes.dart';
import 'calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const Center(child: Text('Home Page')),
    const ClassesPage(),
    const CalendarPage(),
    const ProfilePage(),
  ];

  ValueChanged<int>? get _onItemTapped => (index) {
        setState(() {
          _selectedIndex = index;
        });
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
