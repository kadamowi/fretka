import 'dart:convert';

import 'package:call_log/call_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:phone_state_background/phone_state_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_log.dart';
import 'call_monitor.dart';

@pragma('vm:entry-point')
Future<bool> sendCalls(task) async {
  if (kDebugMode) {
    print('Wysyłka połączeń: $task');
  }

  String dateNow = DateTime.now().toString();
  await logChomik('$dateNow: sendCalls Task:$task');

  final urlCall = Uri.parse('https://ricco.azurewebsites.net//api/call');
  final baseUrlLast = Uri.parse('https://ricco.azurewebsites.net//api/last');
  final headers = {"Content-Type": "application/json", "App": "Fretka"};
  final prefs = await SharedPreferences.getInstance();
  String name = prefs.getString('OwnerName') ?? '-';
  String number = prefs.getString('OwnerNumber') ?? '-';

  if (name == '-') {
    dateNow = DateTime.now().toString();
    await logChomik('$dateNow: sendCalls Brak danych użytkownika');
    return true;
  }
  try {
    // Sprawdzamy co ostanio wrzuciliśmy
    Uri urlLast = Uri(
      scheme: baseUrlLast.scheme,
      host: baseUrlLast.host,
      path: baseUrlLast.path,
      queryParameters: {"owner": name, "taskName": task},
    );
    DateTime lastDate = DateTime.now();
    if (task == "Tech") {
      lastDate = DateTime(2024, 2, 1);
      name = "${name}_$task";
      number = task;
    } else {
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
      } catch (e) {
        await logChomik('$dateNow: sendCalls Error:$e');
        return true;
      }
    }

    dateNow = DateTime.now().toString();
    await logChomik('$dateNow: sendCalls Task:$task LastDay:$lastDate');

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

    dateNow = DateTime.now().toString();
    await logChomik('$dateNow: sendCalls Task:$task CallLogCount:${callLogEntries.length}');

    for (CallLogEntry entry in callLogEntries) {
      DateTime start = DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0);
      if ((entry.duration == null || entry.duration! == 0) && (entry.callType != CallType.outgoing)) continue;

      dateNow = DateTime.now().toString();
      await logChomik('$dateNow: sendCalls Task:$task Entry:${entry.number}');

      String callType = callTypeStr(entry.callType);
      String contactName = 'nieznany';
      if (entry.name != null && entry.name!.isNotEmpty) {
        contactName = entry.name ?? '-';
      }

      String numberText = entry.number ?? '-';
      if (!numberText.startsWith('+')) {
        numberText = '+48$numberText';
      }

      final body = json.encode({
        'Owner': name,
        'ownerNumber': number,
        'contactName': contactName,
        'contact': numberText,
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
    dateNow = DateTime.now().toString();
    await logChomik('$dateNow: sendCalls Task:$task - OK');
    return true;
  } on PlatformException catch (e, s) {
    await logChomik('$dateNow: Exception $e $s');
    return true;
  }
}

@pragma('vm:entry-point')
Future<void> phoneStateBackgroundCallbackHandler(PhoneStateBackgroundEvent event, String number, int duration) async {
  final callMonitor = CallMonitor();

  String dateNow = DateTime.now().toString();
  await logChomik('$dateNow: $event $number $duration');
  addLog('phoneStateBackgroundCallback', '$dateNow: $event $number $duration');

  switch (event) {
    case PhoneStateBackgroundEvent.incomingstart:
      if (kDebugMode) {
        print('Incoming call started');
      }
      addLog('callMonitor', 'startRecording $number');
      await callMonitor.startRecording(number);
      break;
    case PhoneStateBackgroundEvent.incomingreceived:
      break;
    case PhoneStateBackgroundEvent.incomingend:
      if (kDebugMode) {
        print('Call ended');
      }
      addLog('callMonitor', 'stopRecording $number');
      await callMonitor.stopRecording();
      await Future.delayed(const Duration(seconds: 5));
      sendCalls("incomingend");
      break;
    case PhoneStateBackgroundEvent.outgoingstart:
      if (kDebugMode) {
        print('Outgoing call started');
      }
      addLog('callMonitor', 'startRecording $number');
      await callMonitor.startRecording(number);
      break;
    case PhoneStateBackgroundEvent.outgoingend:
      if (kDebugMode) {
        print('Call ended');
      }
      addLog('callMonitor', 'stopRecording $number');
      await callMonitor.stopRecording();
      await Future.delayed(const Duration(seconds: 5));
      sendCalls("outgoingend");
      break;
    case PhoneStateBackgroundEvent.incomingmissed:
      break;
  }
  await callMonitor.disposeRecorder();
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
