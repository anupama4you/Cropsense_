import 'package:flutter/material.dart';
import 'package:cropsense/home_screen.dart';
import 'package:cropsense/messages.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final int homePageIndex = 0;
  final int messagesPageIndex = 1;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0 ? HomeScreen() : Messages(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            label: ("Home"),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.message_outlined,
            ),
            label: 'Messages',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color(0xFF64af69),
        selectedItemColor: Colors.white,
      ),
    );
  }
}
