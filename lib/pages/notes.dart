import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/database_helper.dart';
import '../api/description_api.dart';
import '../api/notes_api.dart';
import '../api/user_info.dart';
import '../forms/add_description.dart';
import '../widgets/item_container.dart';
import '../widgets/page_header.dart';
import '../widgets/theme_container.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  List<dynamic> _notes = [];
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final notes = await DatabaseHelper().getAllNotes();
    setState(() {
      isUpdating = false;
      _notes = notes;
    });
  }

  Future<void> _handleTextChanged(DescriptionType newText) async {
    setState(() {
      isUpdating = true;
    });
    if (newText.id == 0) {
      final note = {'owner': ownerName, 'description': newText.description, 'created': DateTime.now().toString()};
      await DatabaseHelper().insertNote(note);
    } else {
      await DatabaseHelper().updateNoteDescription(newText.id, newText.description);
    }
    await updateNoteAfterSync('Text changed');
    await _fetchNotes();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Column(
        children: [
          const PageHeader(title: 'Notatki'),
          Expanded(
              child: ThemedContainer(
            child: (isUpdating)
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Wyrównanie poziome do środka
                      crossAxisAlignment: CrossAxisAlignment.center, // Wyrównanie pionowe do środka
                      mainAxisSize: MainAxisSize.min, // Dopasowanie szerokości do zawartości
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text("Proszę czekać..."),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      String createdDateText = 'brak';
                      if (note['created'] != null) {
                        DateTime createdDate = DateTime.parse(note['created']);
                        createdDateText = DateFormat('yyyy-MM-dd HH:mm').format(createdDate);
                      }
                      Color? color = Colors.blue[50];
                      if (note['external_id'] == null || note['modified'] != null) {
                        color = Colors.red[50];
                      }
                      return GestureDetector(
                        onLongPress: () {
                          DescriptionType desc = DescriptionType(id: note['id'], description: note['description']);
                          if (kDebugMode) {
                            print('Update note: ${desc.id} ${desc.description}');
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddDescription(
                                      initialDescription: desc,
                                      onTextChanged: _handleTextChanged,
                                    )),
                          );
                        },
                        child: ItemContainer(
                            color: color,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(createdDateText),
                                      Text(note['description'], style: Theme.of(context).textTheme.bodyMedium, softWrap: true),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Usuwanie notatki'),
                                          content: Text('Czy na pewno chcesz usunąć tę notatkę?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Zamknij dialog bez usuwania
                                              },
                                              child: Text('Nie'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                DatabaseHelper().deleteNote(note['id']);
                                                if (note['external_id'] != null) {
                                                  deleteAzureNote(note['external_id']);
                                                }
                                                _fetchNotes();
                                                Navigator.of(context).pop(); // Zamknij dialog po usunięciu
                                              },
                                              child: Text('Tak'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Icon(Icons.delete, color: Colors.red),
                                )
                              ],
                            )),
                      );
                    },
                  ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          DescriptionType desc = DescriptionType(id: 0, description: '');
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddDescription(
                      initialDescription: desc,
                      onTextChanged: _handleTextChanged,
                    )),
          );
        },
        child: const Icon(Icons.add),
      ),
    ));
  }
}
