import 'dart:convert';

import 'package:call_log/call_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../api/calls_info.dart';
import '../api/user_info.dart';
import '../widgets/alert.dart';
import '../widgets/item_container.dart';
import '../widgets/page_header.dart';
import '../widgets/theme_container.dart';

class CallsTab extends StatefulWidget {
  const CallsTab({super.key});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  List<CallLogEntry> _callLogEntries = [];
  DateTime lastSynchroDate = DateTime(2024, 2, 1);
  int deviceCount = 0;
  int toSybchroCount = 0;
  DateTime lastClickSend = DateTime(2024, 2, 1);

  @override
  void initState() {
    if (kDebugMode) {
      print('Calls -> initState');
    }
    getCalls().then((value) {
      setState(() {});
    });
    super.initState();
  }

  Future<void> getCalls() async {
    if (kDebugMode) {
      print('Calls -> _getCalls ($ownerName)');
    }
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
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: <Widget>[
            const PageHeader(title: 'Połączenia'),
            // Połączenia
            Expanded(
              child: ThemedContainer(
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: _callLogEntries.length,
                    itemBuilder: (context, index) {
                      return ItemContainer(
                        child: ListTile(
                            isThreeLine: true,
                            title: Text('${_callLogEntries[index].name} ${_callLogEntries[index].number}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Start: ${DateTime.fromMillisecondsSinceEpoch(_callLogEntries[index].timestamp ?? 0)}'),
                                Text('Czas: ${_callLogEntries[index].duration}'),
                              ],
                            ),
                            leading: callTypeIcon(_callLogEntries[index].callType)),
                      );
                    }),
              ),
            ),
            // Status
            ThemedContainer(
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
                          color: Colors.white,
                        )),
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
