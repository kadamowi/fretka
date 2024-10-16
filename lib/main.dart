import 'dart:convert';

import 'package:call_log/call_log.dart';
import 'package:chomik/add_user_data.dart';
import 'package:chomik/api/user_info.dart';
import 'package:chomik/pages/tasks.dart';
import 'package:chomik/widgets/alert.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/app_log.dart';
import 'api/calls_info.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ricco - historia połączeń',
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
            textColor: Colors.black,
            tileColor: Colors.grey,
            dense: true,
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Ricco - historia połączeń'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  List<CallLogEntry> _callLogEntries = [];
  DateTime lastSynchroDate = DateTime(2024, 2, 1);
  int deviceCount = 0;
  int toSybchroCount = 0;
  bool isActive = false;
  bool hasPermission = false;
  String logDir = "";
  DateTime lastClickSend = DateTime(2024, 2, 1);

  Future<void> _hasPermission() async {
    final permission = await PhoneStateBackground.checkPermission();
    if (mounted) {
      setState(() => hasPermission = permission);
    }
  }

  Future<void> _init() async {
    if (hasPermission != true) return;
    try {
      await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
    } catch (e) {
      String dateNow = DateTime.now().toString();
      await logChomik('$dateNow: Init err, hasPermission: $e');
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    String dateNow = DateTime.now().toString();
    await logChomik('$dateNow: ChangeAppLifecycleState: $state');
    if (state == AppLifecycleState.resumed) {
      await _hasPermission();
    }
  }

  @override
  void initState() {
    getApplicationDocumentsDirectory().then((value) => logDir = value.path);
    WidgetsBinding.instance.addObserver(this);
    _hasPermission();
    super.initState();
    SharedPreferences.getInstance().then((value) {
      preferences = value;
      getUser();
      _init();
      getCalls().then((value) {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> getCalls() async {
    if (ownerName.isNotEmpty) {
      final baseUrlLast = Uri.parse('https://ricco.azurewebsites.net/api/last');
      final headers = {"Content-Type": "application/json", "App": "Fretka"};
      Uri urlLast = Uri(
        scheme: baseUrlLast.scheme,
        host: baseUrlLast.host,
        path: baseUrlLast.path,
        queryParameters: {"owner": ownerName, "taskName": "Refresh"},
      );
      var respGet = await http.get(urlLast, headers: headers);
      String jsonResponse = respGet.body;
      Map<String, dynamic> decoded = json.decode(jsonResponse);
      String dateString = decoded['lastDate'];
      lastSynchroDate = DateTime.parse(dateString);
      final Iterable<CallLogEntry> toSynchResult = await CallLog.query(
        dateFrom: lastSynchroDate.millisecondsSinceEpoch,
      );
      toSybchroCount = toSynchResult.length;
    }

    final Iterable<CallLogEntry> result = await CallLog.query(
      dateFrom: DateTime(2024, 2, 1).millisecondsSinceEpoch,
    );
    _callLogEntries = result.toList();
    deviceCount = _callLogEntries.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            // Sekcja z danymi usera
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Użytkownik: $ownerName'),
                      Text('Telefon: $ownerNumber'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserPage(ownerName: ownerName, ownerNumber: ownerNumber)),
                      ).then((value) {
                        setState(() {
                          getUser();
                        });
                      });
                    },
                    child: const Text('Użytkownik'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            // Przyciski
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await getCalls();
                      setState(() {});
                    },
                    child: Text('Odśwież',
                        style: TextStyle(
                          color: hasPermission ? Colors.white : Colors.red,
                        )),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (lastClickSend.difference(DateTime.now()).abs().inSeconds < 60) {
                        showAlertDialog(context, "Poprzednio uruchomiony proces jeszcze trwa ...");
                      } else {
                        await sendCalls("Wyślij");
                      }
                      lastClickSend = DateTime.now();
                      setState(() {});
                    },
                    child: Text('Wyślij',
                        style: TextStyle(
                          color: hasPermission ? Colors.white : Colors.red,
                        )),
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        final directory = await getApplicationDocumentsDirectory();
                        Share.shareXFiles([XFile('${directory.path}/chomik.log')], text: 'directory.path');
                      },
                      child: const Text('Udostępnij')),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: _callLogEntries.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                          isThreeLine: true,
                          title: Text('${_callLogEntries[index].name} ${_callLogEntries[index].number}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Start: ${DateTime.fromMillisecondsSinceEpoch(_callLogEntries[index].timestamp ?? 0)}'),
                              Text('Czas: ${_callLogEntries[index].duration}'),
                            ],
                          ),
                          leading: callTypeIcon(_callLogEntries[index].callType));
                    }),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Liczba elementów na telefonie: $deviceCount', style: Theme.of(context).textTheme.labelMedium),
                      Text('Ostatnie połączenie: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(lastSynchroDate)}', style: Theme.of(context).textTheme.labelMedium),
                      Text('Liczba elementów do wysłania: $toSybchroCount', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TasksTab()),
                      );
                    },
                    child: const Text('Zadania'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
