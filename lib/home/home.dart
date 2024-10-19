import 'package:firebase_auth/firebase_auth.dart';
import 'package:campfire/home/home_pages/calls_page.dart';
import 'package:campfire/home/home_pages/chats_page.dart';
import 'package:campfire/home/home_pages/feed_page.dart';
import 'package:campfire/home/home_pages/groups_page.dart';
import 'package:campfire/home/home_pages/profile_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
  }

  Future<void> _fetchCurrentUserId() async {
    // Fetch the current logged-in user's ID using Firebase Authentication
    User? currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      userId = currentUser?.uid;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Initialize the pages with the required userId for CallsPage
    final List<Widget> _pages = [
      FeedPage(),
      const GroupsPage(),
      const ChatsPage(),
      CallPage(), // Pass the dynamic userId to CallsPage
      const ProfilePage(),
    ];

    return Scaffold(
      // Body using IndexedStack to maintain state
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // To show all labels
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: 'Calls',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
