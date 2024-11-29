import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  if (Platform.isWindows) {
    databaseFactory = databaseFactoryFfi;
    await windowManager.ensureInitialized();
    windowManager.setTitle('Chomik Windows');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chomik',
      theme: ThemeData(
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.blue[100], // Kolor tła nawigacji
          selectedItemColor: Colors.black, // Kolor dla wybranego elementu
          unselectedItemColor: Colors.blue, // Kolor dla nieaktywnych elementów
          selectedIconTheme: IconThemeData(color: Colors.black, size: 30), // Kolor i rozmiar dla wybranych ikon
          unselectedIconTheme: IconThemeData(color: Colors.grey, size: 25), // Kolor i rozmiar dla nieaktywnych ikon
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primaryContainer: Colors.grey,
          secondaryContainer: Colors.blue[200],
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[300],
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.black, fontSize: 32),
          bodySmall: TextStyle(color: Colors.black, fontSize: 10),
          bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
          bodyLarge: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: Colors.black, fontSize: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(10.0),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            labelStyle: const TextStyle(color: Colors.black, fontSize: 16),
            hintStyle: const TextStyle(color: Colors.black, fontSize: 16),
            fillColor: Colors.cyanAccent,
            filled: true,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
        listTileTheme: const ListTileThemeData(
            textColor: Colors.black, dense: true, titleTextStyle: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
