import 'dart:async';

import 'package:chomik/api/user_info.dart';
import 'package:chomik/pages/calls.dart';
import 'package:chomik/pages/notes.dart';
import 'package:chomik/pages/profile.dart';
import 'package:chomik/pages/tasks.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/app_log.dart';
import 'api/calls_info.dart';
import 'api/notes_api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _StateHomePage();
}

class _StateHomePage extends State<HomePage> {
  final _pageViewController = PageController();
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  int _selectedIndex = 0;
  bool _hasPermission = false;
  bool _isUserLoaded = false;

  Future<void> _checkPermission() async {
    final permission = await PhoneStateBackground.checkPermission();
    if (mounted) {
      setState(() => _hasPermission = permission);
    }
  }

  Future<void> _init() async {
    String dateNow = DateTime.now().toString();
    try {
      await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    } catch (e) {
      await logChomik('$dateNow: HomePage Init error, hasPermission: $_hasPermission, Error: $e');
    }
    await logChomik('$dateNow: HomePage Init');
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      preferences = value;
      getUser();
      initConnectivity();
      setState(() {
        _isUserLoaded = true;
      });
      _checkPermission().then((_) => _init());
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      String dateNow = DateTime.now().toString();
      await logChomik('$dateNow: checkConnectivity error: $e');
      return;
    }
    if (!mounted) {
      return Future.value(null);
    }
    String dateNow = DateTime.now().toString();
    await logChomik('$dateNow: initConnectivity: $result');
    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    String dateNow = DateTime.now().toString();
    await logChomik('$dateNow: updateConnectionStatus: $result');
    if (!result.contains(ConnectivityResult.none)) {
      updateNoteAfterSync('Conectivity');
    }
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
                  NotesTab(),
                  ProfileTab(),
                ],
                onPageChanged: (index) {
                  _selectedIndex = index;
                  if (mounted) {
                    setState(() {});
                  }
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
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'Notatki'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profil'),
        ],
      ),
    );
  }
}
