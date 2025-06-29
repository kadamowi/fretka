import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<void> logChomik(String textLog) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    if (kDebugMode) {
      print("Katalog: ${directory.path}");
    }
    final logFile = File('${directory.path}/chomik.log');
    await logFile.writeAsString('\n$textLog', mode: FileMode.append); // Dopisz dane do pliku
  } catch (e) {
    if (kDebugMode) {
      print("Wystąpił błąd podczas zapisywania do pliku: $e");
    }
  }
}

Future<void> deleteLogChomik() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logFile = File('${directory.path}/chomik.log');

    if (await logFile.exists()) {
      await logFile.delete();
      if (kDebugMode) {
        print("Plik chomik.log został usunięty.");
      }
    } else {
      if (kDebugMode) {
        print("Plik chomik.log nie istnieje.");
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("Wystąpił błąd podczas kasowania pliku: $e");
    }
  }
}

List<MapEntry<String, String>> logInfo = [];

void addLog(String place, String message) {
  if (kDebugMode) {
    print('$place: $message');
  }
  logInfo.add(MapEntry(place, message));
}
