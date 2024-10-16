import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/user_info.dart';
import '../widgets/item_container.dart';
import '../widgets/page_header.dart';
import '../widgets/theme_container.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  List<dynamic> _tasks = [];

  @override
  void initState() {
    if (kDebugMode) {
      print('Tasks -> initState');
    }
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    if (kDebugMode) {
      print('Tasks -> _fetchTasks ($ownerName)');
    }
    final baseUrlLast = Uri.parse('https://ricco.azurewebsites.net/api/tasks');
    final headers = {"Content-Type": "application/json", "App": "Fretka"};
    Uri urlLast = Uri(
      scheme: baseUrlLast.scheme,
      host: baseUrlLast.host,
      path: baseUrlLast.path,
      queryParameters: {"owner": ownerName},
    );
    final response = await http.get(urlLast, headers: headers);

    if (response.statusCode == 200) {
      setState(() {
        _tasks = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Column(
        children: [
          const PageHeader(title: 'Zadania w Ricco'),
          Expanded(
              child: ThemedContainer(
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ItemContainer(
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
                      task['appDetails'],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      task['title'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ));
              },
            ),
          )),
        ],
      ),
    ));
  }
}
