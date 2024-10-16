import 'dart:io';

import 'package:flutter/foundation.dart';
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
