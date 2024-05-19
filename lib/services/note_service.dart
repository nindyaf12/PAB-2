import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:notes/models/note.dart';

class NoteService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final CollectionReference _notesCollection = _database.collection('notes');
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<void> addNote(Note note) async {
    Map<String, dynamic> newNote = {
      'title': note.title,
      'description': note.description,
      'image_url': note.imageUrl,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await _notesCollection.add(newNote);
  }

  static Stream<List<Note>> getNoteList() {
    return _notesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Note(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          imageUrl: data['image_url'],
          createdAt: data['created_at'] != null ? data['created_at'] as Timestamp : null,
          updatedAt: data['updated_at'] != null ? data['updated_at'] as Timestamp : null,
        );
      }).toList();
    });
  }

  static Future<void> updateNote(Note note) async {
    Map<String, dynamic> updateNote = {
      'title': note.title,
      'description': note.description,
      'image_url': note.imageUrl,
      'created_at': note.createdAt,
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _notesCollection.doc(note.id).update(updateNote);
  }

  static Future<void> deleteNote(Note note) async {
    await _notesCollection.doc(note.id).delete();
  }

  static Future<String?> uploadImage(Uint8List imageBytes, String imageName) async {
    try {
      Reference ref = _storage.ref().child('images/$imageName');
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }
}
