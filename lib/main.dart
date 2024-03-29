import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:chomik/add_user_data.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:call_log/call_log.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> logChomik(String textLog) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    if (kDebugMode) {
      print("Katalog $directory.path");
    }
    final logFile = File('${directory.path}/chomik.log');
    await logFile.writeAsString('\n$textLog', mode: FileMode.append); // Dopisz dane do pliku
  } catch (e) {
    if (kDebugMode) {
      print("Wystąpił błąd podczas zapisywania do pliku: $e");
    }
  }
}


@pragma('vm:entry-point')
Future<bool> sendCalls(task) async {
  if (kDebugMode) {
    print('Wysyłka połączeń: $task');
  }

  String dateNow = DateTime.now().toString();
  await logChomik('$dateNow: sendCalls Task:$task');

  final urlCall = Uri.parse('https://ricco.azurewebsites.net//api/call');
  final baseUrlLast = Uri.parse('https://ricco.azurewebsites.net//api/last');
  final headers = {
    "Content-Type": "application/json",
    "App": "Fretka"
  };
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString('OwnerName') ?? '-';
  final number = prefs.getString('OwnerNumber') ?? '-';

  if (name == '-') {
    if (kDebugMode) {
      print('Brak danych użytkownika');
    }
    return true;
  }
  try {
    // Sprawdzamy co ostanio wrzuciliśmy
    Uri urlLast = Uri(
      scheme: baseUrlLast.scheme,
      host: baseUrlLast.host,
      path: baseUrlLast.path,
      queryParameters: {
        "owner": name,
        "taskName": task
      },
    );
    DateTime lastDate = DateTime.now();
    try {
      var respGet = await http.get(urlLast, headers: headers);
      String jsonResponse = respGet.body;
      if (respGet.statusCode != 200) {
        await logChomik('$dateNow: sendCalls Error StatusCode:${respGet.statusCode}');
        return true;
      }
      Map<String, dynamic> decoded = json.decode(jsonResponse);
      String dateString = decoded['lastDate'];
      lastDate = DateTime.parse(dateString);
    } catch(e) {
      await logChomik('$dateNow: sendCalls Error:$e');
      return true;
    }

    final Iterable<CallLogEntry> cLog = await CallLog.query(
      dateFrom: lastDate.millisecondsSinceEpoch,
    );
    List<CallLogEntry> callLogEntries = cLog.toList();
    callLogEntries.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) {
        return 0;
      } else if (a.timestamp == null) {
        return 1;
      } else if (b.timestamp == null) {
        return -1;
      } else {
        return a.timestamp!.compareTo(b.timestamp!);
      }
    });

    for (CallLogEntry entry in callLogEntries) {
      DateTime start = DateTime.fromMillisecondsSinceEpoch(entry.timestamp??0);
      if (entry.duration == null || entry.duration! == 0) continue;

      String callType = callTypeStr(entry.callType);
      String contactName = 'nieznany';
      if (entry.name != null && entry.name!.isNotEmpty) {
        contactName = entry.name ?? '-';
      }

      final body = json.encode({
        'Owner': name,
        'ownerNumber': number,
        'contactName':  contactName,
        'contact': entry.number,
        'contactType': callType,
        'callStart': start.toIso8601String(),
        'callDuration': entry.duration.toString()
      });

      try {
        var response = await http.post(urlCall, headers: headers, body: body);
        if (response.statusCode == 200) {
          if (kDebugMode) {
            print("Odpowiedź serwera: ${response.body}");
          }
        } else {
          await logChomik('$dateNow: Błąd serwera: ${response.statusCode} [${response.body}]');
        }
      } catch (e) {
        await logChomik('$dateNow: SendCalls http.post:$e');
      }
    }
    return true;
  } on PlatformException catch (e, s) {
    await logChomik('$dateNow: Exception $e $s');
    return true;
  }
}

@pragma('vm:entry-point')
Future<void> phoneStateBackgroundCallbackHandler(
    PhoneStateBackgroundEvent event,
    String number,
    int duration,
    ) async {

  String dateNow = DateTime.now().toString();
  await logChomik('$dateNow: $event $number $duration');

  switch (event) {
    case PhoneStateBackgroundEvent.incomingstart:
      break;
    case PhoneStateBackgroundEvent.incomingreceived:
      break;
    case PhoneStateBackgroundEvent.incomingend:
      await Future.delayed(const Duration(seconds: 5));
      sendCalls("incomingend");
      break;
    case PhoneStateBackgroundEvent.outgoingstart:
      break;
    case PhoneStateBackgroundEvent.outgoingend:
      await Future.delayed(const Duration(seconds: 5));
      sendCalls("outgoingend");
      break;
    case PhoneStateBackgroundEvent.incomingmissed:
      await Future.delayed(const Duration(seconds: 5));
      sendCalls("incomingmissed");
      break;
  }
}

String callTypeStr(CallType? callTypeEntry) {
  String callType;
  switch (callTypeEntry) {
    case null:
      callType = "-";
      break;
    case CallType.incoming:
      callType = "przychodzący";
      break;
    case CallType.outgoing:
      callType = "wychodzący";
      break;
    case CallType.missed:
      callType = "pominięty";
      break;
    case CallType.voiceMail:
      callType = "voiceMail";
      break;
    case CallType.rejected:
      callType = "odrzucony";
      break;
    case CallType.blocked:
      callType = "zablokowany";
      break;
    case CallType.answeredExternally:
      callType = "answeredExternally";
      break;
    case CallType.unknown:
      callType = "unknown";
      break;
    case CallType.wifiIncoming:
      callType = "wifiIncoming";
      break;
    case CallType.wifiOutgoing:
      callType = "wifiOutgoing";
      break;
  }
  return callType;
}


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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          background: Colors.grey[600],
          primaryContainer: Colors.grey,
          secondaryContainer: Colors.blue[200],
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[600],
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.black,fontSize: 32),
          bodySmall: TextStyle(color: Colors.black,fontSize: 10),
          bodyMedium: TextStyle(color: Colors.black,fontSize: 16, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.black,fontSize: 20, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: Colors.black,fontSize: 18),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
        ),
        listTileTheme: const ListTileThemeData(
            textColor: Colors.black,
            tileColor: Colors.grey,
            dense: true,
            titleTextStyle: TextStyle(color: Colors.black,fontSize: 16, fontWeight: FontWeight.bold)
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ricco - historia połączeń'),
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
  static late SharedPreferences _preferences;
  List<CallLogEntry> _callLogEntries = [];
  String ownerName = "";
  String ownerNumber = "";
  DateTime lastSynchroDate = DateTime(2024, 2, 1);
  int deviceCount = 0;
  int toSybchroCount = 0;
  bool isActive = false;
  bool hasPermission = false;
  String logDir = "";

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
      _preferences = value;
      getUser();
      _init();
      getCalls().then((value) {
        setState(() {
        });
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void getUser() {
    var x = _preferences.getString('OwnerName');
    if (x != null) {
      ownerName = x;
    }
    x = _preferences.getString('OwnerNumber');
    if (x != null) {
      ownerNumber = x;
    }
  }

  Future<void> getCalls() async {
    if (ownerName.isNotEmpty) {
      final baseUrlLast = Uri.parse('https://ricco.azurewebsites.net/api/last');
      final headers = {
        "Content-Type": "application/json",
        "App": "Fretka"
      };
      Uri urlLast = Uri(
        scheme: baseUrlLast.scheme,
        host: baseUrlLast.host,
        path: baseUrlLast.path,
        queryParameters: {
          "owner": ownerName,
          "taskName": "Refresh"
        },
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
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0)
              ),
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
                        MaterialPageRoute(
                            builder: (context) => UserPage(ownerName: ownerName, ownerNumber: ownerNumber)
                        ),
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
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0)
              ),
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
                      await sendCalls("Odwież");
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
                    child: const Text('Udostępnij')
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0)
                ),
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
                              Text('Start: ${DateTime.fromMillisecondsSinceEpoch(_callLogEntries[index].timestamp??0)}'),
                              Text('Czas: ${_callLogEntries[index].duration}'),
                            ],
                          ),
                          leading: callTypeIcon(_callLogEntries[index].callType)
                      );
                    }
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0)
              ),
              padding: const EdgeInsets.all(5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Liczba elementów na telefonie: $deviceCount', style: Theme.of(context).textTheme.labelMedium),
                  Text('Ostatnie połączenie: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(lastSynchroDate)}', style: Theme.of(context).textTheme.labelMedium),
                  Text('Liczba elementów do wysłania: $toSybchroCount', style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Icon callTypeIcon(CallType? call) {
    switch (call) {
      case null:
        return const Icon(Icons.help);
      case CallType.incoming:
        return const Icon(Icons.arrow_downward);
      case CallType.outgoing:
        return const Icon(Icons.arrow_upward);
      case CallType.missed:
        return const Icon(Icons.hourglass_full);
      case CallType.voiceMail:
        return const Icon(Icons.email);
      case CallType.rejected:
        return const Icon(Icons.cancel);
      case CallType.blocked:
        return const Icon(Icons.help);
      case CallType.answeredExternally:
        return const Icon(Icons.help);
      case CallType.unknown:
        return const Icon(Icons.help);
      case CallType.wifiIncoming:
        return const Icon(Icons.help);
      case CallType.wifiOutgoing:
        return const Icon(Icons.help);
    }
  }
}
