import 'dart:convert';

import 'package:chomik/api/user_info.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_log.dart';
import 'database_helper.dart';

final baseUrl = Uri.parse('https://ricco.azurewebsites.net/api/note');
final baseUrlNotes = Uri.parse('https://ricco.azurewebsites.net/api/notes');
final headers = {"Content-Type": "application/json", "App": "Fretka"};

class NoteType {
  int id;
  String noteDate;
  String owner;
  String description;

  NoteType({required this.id, required this.noteDate, required this.owner, required this.description});
}

Future<int> addAzureNote(String owner, String created, String description) async {
  try {
    Uri uriPost = Uri.parse('$baseUrl');
    var respPost = await http.post(
      uriPost,
      headers: headers,
      body: jsonEncode({"created": created.substring(0, 16), "owner": owner, "description": description}),
    );
    if (respPost.statusCode != 200) {
      return 0;
    } else {
      String jsonResponse = respPost.body;
      Map<String, dynamic> decoded = json.decode(jsonResponse);
      return decoded['id'];
    }
  } catch (e) {
    return 0;
  }
}

Future<void> updateAzureNote(int id, String description) async {
  String dateNow = DateTime.now().toString();
  try {
    Uri uriPut = Uri.parse('$baseUrl/$id');
    var respPut = await http.put(
      uriPut,
      headers: headers,
      body: jsonEncode({
        "description": description,
      }),
    );
    if (respPut.statusCode != 200) {
      await logChomik('$dateNow: updateNote Error StatusCode:${respPut.statusCode}');
    }
  } catch (e) {
    await logChomik('$dateNow: updateNote Error:$e');
  }
}

Future<void> deleteAzureNote(int id) async {
  String dateNow = DateTime.now().toString();
  try {
    Uri uriDelete = Uri.parse('$baseUrl/$id');
    var respDelete = await http.delete(uriDelete, headers: headers);
    if (respDelete.statusCode != 200) {
      await logChomik('$dateNow: deleteNote Error StatusCode:${respDelete.statusCode}');
    }
  } catch (e) {
    await logChomik('$dateNow: deleteNote Error:$e');
  }
}

Future<List<dynamic>?> getAzureNotes() async {
  if (ownerName.isEmpty) return null;
  if (kDebugMode) {
    print('getAzureNotes: $ownerName');
  }
  Uri urlNotes = Uri(
    scheme: baseUrlNotes.scheme,
    host: baseUrlNotes.host,
    path: baseUrlNotes.path,
    queryParameters: {"owner": ownerName},
  );
  List<dynamic>? azureNotes;
  try {
    final response = await http.get(urlNotes, headers: headers);
    if (response.statusCode == 200) {
      azureNotes = json.decode(response.body);
    } else {
      if (kDebugMode) {
        print('Error getAzureNotes url:$urlNotes');
        print('ownerName: $ownerName');
        print('statusCode: ${response.statusCode}');
        print('body: ${response.body}');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error getAzureNotes');
    }
  }
  return azureNotes;
}

bool isSynchro = false;

Future<void> updateNoteAfterSync(String source) async {
  if (kDebugMode) {
    print('updateNoteAfterSync: $source isSynchro=$isSynchro');
  }

  if (isSynchro) return;
  isSynchro = true;

  final azureNotes = await getAzureNotes();
  if (azureNotes == null) {
    if (kDebugMode) {
      print('  getAzureNotes: brak notatek');
    }
    isSynchro = false;
    return;
  }
  if (kDebugMode) {
    print('  getAzureNotes: azureNotes.length ${azureNotes.length}');
  }

  final allNotes = await DatabaseHelper().getAllNotes();
  if (kDebugMode) {
    print('  getAllNotes: allNotes.length ${allNotes.length}');
  }

  for (var note in allNotes) {
    if (kDebugMode) {
      print('  Note ${note['id']} (${note['external_id']}) - ${note['description']}');
    }
    int? extId = note["external_id"];
    // Jak pusto to wysyłamy na Azure i ustawiamy zewnętrzne id
    if (extId == null) {
      int externalId = await addAzureNote(note["owner"], note["created"], note["description"]);
      if (kDebugMode) {
        print('    Sended $externalId');
      }
      if (externalId > 0) {
        await DatabaseHelper().updateNoteExternalId(note['id'], externalId);
      }
    } else {
      // Sprawdzamy czy ta notatka jest na Azure
      bool inAzure = azureNotes.any((note) => note['id'] == extId);
      if (inAzure) {
        // istnieje sprawdzamy więc czy była modyfikowana
        if (note['modified'] != null) {
          if (kDebugMode) {
            print('    Updated $extId ${note['modified']}');
          }
          await updateAzureNote(extId, note["description"]);
          await DatabaseHelper().updateNoteModifiedNull(note['id']);
        }
      } else {
        if (kDebugMode) {
          print('    Deleted $extId ${note['modified']}');
        }
        // Nie istnieje więc kasujemy notatkę
        await DatabaseHelper().deleteAzureNote(extId);
      }
    }
  }
  isSynchro = false;
}
