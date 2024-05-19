import 'package:flutter/material.dart';
import 'package:notes/services/note_service.dart';
import 'package:notes/widgets/note_dialog.dart';
import 'package:notes/models/note.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({Key? key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: const NoteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final updatedNote = await showDialog<Note>(
            context: context,
            builder: (context) {
              return const NoteDialog();
            },
          );

          if (updatedNote != null) {
            setState(() {}); // Refresh the state to reflect changes
          }
        },
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteList extends StatefulWidget {
  const NoteList({Key? key});

  @override
  State<NoteList> createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: NoteService.getNoteList(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(
              child: CircularProgressIndicator(),
            );
          default:
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No notes available'),
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: snapshot.data!.map((document) {
                return Card(
                  child: InkWell(
                    onTap: () async {
                      final updatedNote = await showDialog<Note>(
                        context: context,
                        builder: (context) {
                          return NoteDialog(note: document);
                        },
                      );

                      if (updatedNote != null) {
                        setState(() {}); // Refresh the state to reflect changes
                      }
                    },
                    child: Column(
                      children: [
                        if (document.imageUrl != null &&
                            Uri.parse(document.imageUrl!).isAbsolute)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(18),
                            ),
                            child: Image.network(
                              document.imageUrl!,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: 150,
                            ),
                          )
                        else
                          Container(),
                        ListTile(
                          title: Text(document.title),
                          subtitle: Text(document.description),
                          trailing: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: Text(
                                        'Are you sure you want to delete "${document.title}"?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('Delete'),
                                        onPressed: () async {
                                          await NoteService.deleteNote(document);
                                          Navigator.of(context).pop();
                                          setState(() {}); // Refresh the state to reflect changes
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Icon(Icons.delete),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
        }
      },
    );
  }
}
