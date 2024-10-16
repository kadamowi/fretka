import 'package:chomik/api/user_info.dart';
import 'package:chomik/pages/calls.dart';
import 'package:chomik/pages/profile.dart';
import 'package:chomik/pages/tasks.dart';
import 'package:flutter/material.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/app_log.dart';
import 'api/calls_info.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _StateHomePage();
}

class _StateHomePage extends State<HomePage> {
  final _pageViewController = PageController();
  int _selectedIndex = 0;
  bool hasPermission = false;
  bool _isUserLoaded = false;

  Future<void> _checkPermission() async {
    final permission = await PhoneStateBackground.checkPermission();
    if (mounted) {
      setState(() => hasPermission = permission);
    }
  }

  Future<void> _init() async {
    try {
      await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
    } catch (e) {
      String dateNow = DateTime.now().toString();
      await logChomik('$dateNow: Init error, hasPermission: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermission();
    SharedPreferences.getInstance().then((value) {
      preferences = value;
      getUser();
      setState(() {
        _isUserLoaded = true;
      });
      _checkPermission().then((_) => _init());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserLoaded) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ); // Show loading indicator until user data is loaded
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageViewController,
                children: const [
                  CallsTab(),
                  TasksTab(),
                  ProfileTab(),
                ],
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          _pageViewController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        },
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Połączenia'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Zadania'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profil'),
        ],
      ),
    );
  }
}
