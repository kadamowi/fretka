import 'dart:convert';

import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../api/calls_info.dart';
import '../api/description_api.dart';
import '../api/user_info.dart';
import '../forms/add_description.dart';
import '../widgets/item_container.dart';
import '../widgets/page_header.dart';
import '../widgets/theme_container.dart';

class CallsTab extends StatefulWidget {
  const CallsTab({super.key});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> with WidgetsBindingObserver {
  List<CallLogEntry> _callLogEntries = [];
  DateTime lastSynchroDate = DateTime.now().add(Duration(days: -30));
  int deviceCount = 0;
  int toSynchroCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getCalls().then((value) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getCalls().then((value) {
        setState(() {});
      });
    }
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
      toSynchroCount = toSynchResult.length;
    }

    final Iterable<CallLogEntry> result = await CallLog.query(
      dateFrom: DateTime.now().add(Duration(days: -30)).millisecondsSinceEpoch,
    );
    _callLogEntries = result.toList();
    deviceCount = _callLogEntries.length;
  }

  Future<void> _performSendCalls() async {
    _isLoading = true;
    if (mounted) {
      setState(() {});
    }

    await sendCalls("Wyślij");
    await Future.delayed(Duration(seconds: 15));
    _isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTextChanged(DescriptionType newText) {
    setState(() {
      setDescription(newText);
    });
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
                      DateTime start = DateTime.fromMillisecondsSinceEpoch(_callLogEntries[index].timestamp ?? 0);
                      return ItemContainer(
                        child: ListTile(
                          isThreeLine: true,
                          title: Text('${_callLogEntries[index].name ?? '???'} ${_callLogEntries[index].number ?? '???'}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Start: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(start)}'),
                              Text('Czas: ${_callLogEntries[index].duration}'),
                            ],
                          ),
                          leading: callTypeIcon(_callLogEntries[index].callType),
                          trailing: InkWell(
                            onTap: () {
                              String formattedDate = DateFormat('yyyyMMddHHmmss').format(start);
                              DescriptionType desc = DescriptionType(id: 0, description: '');
                              getDescription(formattedDate).then((value) {
                                desc = value;
                                if (desc.id > 0) {
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AddDescription(
                                                initialDescription: desc,
                                                onTextChanged: _handleTextChanged,
                                              )),
                                    );
                                  }
                                }
                              });
                            },
                            child: Icon(Icons.description, size: 50),
                          ),
                        ),
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
                      Text('Liczba elementów (30 dni) na telefonie: $deviceCount', style: Theme.of(context).textTheme.labelMedium),
                      Text('Ostatnie połączenie: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(lastSynchroDate)}', style: Theme.of(context).textTheme.labelMedium),
                      Text('Liczba elementów do wysłania: $toSynchroCount', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _performSendCalls,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Wyślij',
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
