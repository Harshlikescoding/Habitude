import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> notes = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedNotes = prefs.getString('notes');
    if (savedNotes != null) {
      List<dynamic> decoded = jsonDecode(savedNotes);
      setState(() {
        notes = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  Future<void> _saveNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', jsonEncode(notes));
  }

  void _addOrEditNote({Map<String, dynamic>? existingNote, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: existingNote),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (index != null) {
          notes[index] = result;
        } else {
          notes.add(result);
        }
      });
      _saveNotes();
    }
  }

  void _deleteNote(int index) {
    final deletedNote = notes.removeAt(index);
    _saveNotes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              notes.insert(index, deletedNote);
            });
            _saveNotes();
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredNotes {
    if (searchQuery.isEmpty) return notes;
    return notes
        .where((note) =>
            (note['title'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
            (note['body'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  List<Map<String, dynamic>> get sortedNotes {
    final pinned = filteredNotes.where((note) => note['isPinned'] == true).toList();
    final others = filteredNotes.where((note) => note['isPinned'] != true).toList();
    return [...pinned, ...others];
  }

  Color _getColor(String color) {
    switch (color) {
      case "Yellow":
        return Colors.yellow[100]!;
      case "Blue":
        return Colors.blue[100]!;
      case "Green":
        return Colors.green[100]!;
      case "Pink":
        return Colors.pink[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search notes...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            Expanded(
              child: sortedNotes.isEmpty
                  ? const Center(child: Text('No Notes Yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sortedNotes.length,
                      itemBuilder: (context, index) {
                        final note = sortedNotes[index];
                        return Dismissible(
                          key: UniqueKey(),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteNote(notes.indexOf(note)),
                          child: Card(
                            color: _getColor(note['color'] ?? ''),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                note['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((note['body'] ?? '').isNotEmpty)
                                    Text(
                                      note['body'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Last edited: ${note['lastEdited']}",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  note['isPinned'] == true ? Icons.push_pin : Icons.push_pin_outlined,
                                  color: Colors.teal,
                                ),
                                onPressed: () {
                                  setState(() {
                                    note['isPinned'] = !(note['isPinned'] ?? false);
                                  });
                                  _saveNotes();
                                },
                              ),
                              onTap: () => _addOrEditNote(existingNote: note, index: notes.indexOf(note)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteEditorPage extends StatefulWidget {
  final Map<String, dynamic>? note;
  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  String selectedColor = "Yellow";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?['title'] ?? '');
    _bodyController = TextEditingController(text: widget.note?['body'] ?? '');
    selectedColor = widget.note?['color'] ?? "Yellow";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, {
                'title': _titleController.text.trim(),
                'body': _bodyController.text.trim(),
                'color': selectedColor,
                'isPinned': widget.note?['isPinned'] ?? false,
                'lastEdited': DateTime.now().toString().substring(0, 16),
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Choose Color: "),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedColor,
                  items: const [
                    DropdownMenuItem(value: "Yellow", child: Text("Yellow")),
                    DropdownMenuItem(value: "Blue", child: Text("Blue")),
                    DropdownMenuItem(value: "Green", child: Text("Green")),
                    DropdownMenuItem(value: "Pink", child: Text("Pink")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedColor = val);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
