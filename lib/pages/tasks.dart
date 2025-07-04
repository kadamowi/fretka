import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/app_log.dart';
import '../api/user_info.dart';
import '../widgets/item_container.dart';
import '../widgets/page_header.dart';
import '../widgets/theme_container.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> with WidgetsBindingObserver {
  List<dynamic> _tasks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchTasks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchTasks();
    }
  }

  Future<void> _fetchTasks() async {
    final baseUrlTask = Uri.parse('https://ricco.azurewebsites.net/api/tasks');
    final headers = {"Content-Type": "application/json", "App": "Fretka"};
    Uri urlTask = Uri(
      scheme: baseUrlTask.scheme,
      host: baseUrlTask.host,
      path: baseUrlTask.path,
      queryParameters: {"owner": ownerName},
    );
    final response = await http.get(urlTask, headers: headers);

    if (response.statusCode == 200) {
      _tasks = json.decode(response.body);
      if (mounted) {
        setState(() {});
      }
    } else {
      if (kDebugMode) {
        print('_fetchTasks: $urlTask');
        print('ownerName: $ownerName');
        print('statusCode: ${response.statusCode}');
        print('body: ${response.body}');
      }
    }
  }

  Future<void> setTaskStatus(String id, String status) async {
    final baseUrl = Uri.parse('https://ricco.azurewebsites.net/api/tasks');
    final headers = {"Content-Type": "application/json", "App": "Fretka"};
    String dateNow = DateTime.now().toString();
    String newStatus = (status == 'Wykonane') ? 'Realizowane' : 'Wykonane';

    try {
      Uri uriPut = Uri.parse('$baseUrl/$id');
      var respPut = await http.put(
        uriPut,
        headers: headers,
        body: jsonEncode({
          "status": newStatus,
        }),
      );
      if (respPut.statusCode != 200) {
        await logChomik('$dateNow: setStatus Error StatusCode:${respPut.statusCode}');
      } else {
        // Ponowne pobranie zadań po udanym ustawieniu statusu
        await _fetchTasks();
      }
    } catch (e) {
      await logChomik('$dateNow: setStatus Error:$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Column(
        children: [
          const PageHeader(title: 'Zadania'),
          Expanded(
              child: ThemedContainer(
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                Color textColor = Colors.black;
                DateTime taskStart = DateTime.parse(task['executionDate']);
                DateTime today = DateTime.now();
                DateTime justToday = DateTime(today.year, today.month, today.day);
                if (taskStart.isBefore(justToday)) {
                  textColor = Colors.red;
                }
                if (taskStart.isAfter(justToday)) {
                  textColor = Colors.blue;
                }
                if (task['status'].toString() == 'Wykonane') {
                  textColor = Colors.green;
                }
                return GestureDetector(
                  onLongPress: () {
                    setTaskStatus(task['id'].toString(), task['status'].toString());
                  },
                  child: ItemContainer(
                      child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(task['executionDate'].toString().substring(0, 10)),
                          Text(task['appname']),
                        ],
                      ),
                      Text(
                        task['title'],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor),
                      ),
                      Text(
                        task['appDetails'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )),
                );
              },
            ),
          )),
        ],
      ),
    ));
  }
}
