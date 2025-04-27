import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> getRecordingPath() async {
  // Uzyskaj główny katalog zewnętrznej pamięci
  final directory = await getExternalStorageDirectory();

  // Stwórz katalog "Chomik", jeśli jeszcze nie istnieje
  final recordingsDir = Directory('${directory!.path}/chomik');
  if (!await recordingsDir.exists()) {
    await recordingsDir.create(recursive: true);
  }

  // Zwróć pełną ścieżkę pliku
  return recordingsDir.path;
}
