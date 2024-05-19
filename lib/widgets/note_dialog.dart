import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:notes/models/note.dart';
import 'package:notes/services/note_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NoteDialog extends StatefulWidget {
  final Note? note;

  const NoteDialog({Key? key, this.note}) : super(key: key);

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.description;
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final imageFile = await ImagePickerWeb.getImageAsBytes();
      if (imageFile != null) {
        setState(() {
          _imageBytes = imageFile;
          _imageName = 'picked_image.png'; // Better name is recommended
        });
      }
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Add Notes' : 'Update Notes'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title: '),
            TextField(controller: _titleController),
            const Padding(padding: EdgeInsets.only(top: 20), child: Text('Description: ')),
            TextField(controller: _descriptionController, maxLines: null),
            const Padding(padding: EdgeInsets.only(top: 20), child: Text('Image: ')),
            _imageBytes != null
                ? Image.memory(_imageBytes!, fit: BoxFit.cover, height: 150)
                : (widget.note?.imageUrl != null && Uri.parse(widget.note!.imageUrl!).isAbsolute
                    ? Image.network(widget.note!.imageUrl!, fit: BoxFit.cover, height: 150)
                    : Container()),
            TextButton(onPressed: _pickImage, child: const Text('Pick Image')),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            String? imageUrl;
            if (_imageBytes != null) {
              imageUrl = await NoteService.uploadImage(_imageBytes!, _imageName!);
              print('Uploaded Image URL: $imageUrl'); // Debugging log
            } else {
              imageUrl = widget.note?.imageUrl;
            }

            Note note = Note(
              id: widget.note?.id,
              title: _titleController.text,
              description: _descriptionController.text,
              imageUrl: imageUrl,
              createdAt: widget.note?.createdAt,
            );

            if (widget.note == null) {
              await NoteService.addNote(note);
            } else {
              await NoteService.updateNote(note);
            }

            Navigator.of(context).pop(note);
          },
          child: Text(widget.note == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
