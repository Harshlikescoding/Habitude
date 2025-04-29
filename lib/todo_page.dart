import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  List<Map<String, dynamic>> tasks = [];
  String searchQuery = '';
  String filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTasks = prefs.getString('tasks');
    if (savedTasks != null) {
      List decoded = jsonDecode(savedTasks);
      setState(() {
        tasks = decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  void _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('tasks', jsonEncode(tasks));
  }

  void _addOrEditTask({Map<String, dynamic>? existingTask, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditorPage(task: existingTask),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (index != null) {
          tasks[index] = result;
        } else {
          tasks.add(result);
        }
      });
      _saveTasks();
    }
  }

  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
    _saveTasks();
  }

  List<Map<String, dynamic>> _filteredTasks() {
    var filtered = tasks.where((task) {
      final matchesSearch = task['title'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesFilter = filter == 'All' || (filter == 'Completed' && task['isCompleted']) || (filter == 'Pending' && !task['isCompleted']);
      return matchesSearch && matchesFilter;
    }).toList();

    filtered.sort((a, b) {
      if (a['isPinned'] == true && b['isPinned'] != true) return -1;
      if (a['isPinned'] != true && b['isPinned'] == true) return 1;
      return DateTime.parse(a['dueDate']).compareTo(DateTime.parse(b['dueDate']));
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = await showSearch(
                context: context,
                delegate: TaskSearchDelegate(tasks: tasks),
              );
              if (query != null) setState(() => searchQuery = query);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => filter = val),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Completed', child: Text('Completed')),
              PopupMenuItem(value: 'Pending', child: Text('Pending')),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _filteredTasks().isEmpty
            ? const Center(child: Text('No Tasks'))
            : ListView.builder(
                itemCount: _filteredTasks().length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks()[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Checkbox(
                        value: task['isCompleted'],
                        onChanged: (val) {
                          setState(() => task['isCompleted'] = val);
                          _saveTasks();
                        },
                      ),
                      title: Text(task['title'], style: TextStyle(decoration: task['isCompleted'] ? TextDecoration.lineThrough : null)),
                      subtitle: Text('Due: ${DateFormat('MMM d, yyyy').format(DateTime.parse(task['dueDate']))}'),
                      trailing: IconButton(
                        icon: Icon(task['isPinned'] ? Icons.push_pin : Icons.push_pin_outlined),
                        onPressed: () {
                          setState(() => task['isPinned'] = !(task['isPinned'] ?? false));
                          _saveTasks();
                        },
                      ),
                      onTap: () => _addOrEditTask(existingTask: task, index: tasks.indexOf(task)),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTask(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskEditorPage extends StatefulWidget {
  final Map<String, dynamic>? task;

  const TaskEditorPage({super.key, this.task});

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  String _priority = 'Medium';
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.task?['description'] ?? '');
    _dueDate = widget.task != null ? DateTime.parse(widget.task!['dueDate']) : null;
    _priority = widget.task?['priority'] ?? 'Medium';
    if (widget.task != null && widget.task!['reminderTime'] != null) {
      final timeParts = (widget.task!['reminderTime'] as String).split(":");
      _reminderTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _reminderTime = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_titleController.text.trim().isNotEmpty && _dueDate != null) {
                Navigator.pop(context, {
                  'title': _titleController.text.trim(),
                  'description': _descriptionController.text.trim(),
                  'dueDate': _dueDate!.toIso8601String(),
                  'priority': _priority,
                  'reminderTime': _reminderTime != null ? "${_reminderTime!.hour}:${_reminderTime!.minute}" : null,
                  'isCompleted': widget.task?['isCompleted'] ?? false,
                  'isPinned': widget.task?['isPinned'] ?? false,
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                maxLines: null,
                decoration: const InputDecoration(hintText: 'Description...', border: InputBorder.none),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(_dueDate != null ? DateFormat('MMM d, yyyy').format(_dueDate!) : 'Pick Due Date'),
                onTap: _pickDueDate,
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_reminderTime != null ? _reminderTime!.format(context) : 'Set Reminder Time'),
                onTap: _pickReminderTime,
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: DropdownButton<String>(
                  value: _priority,
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (val) => setState(() => _priority = val!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> tasks;

  TaskSearchDelegate({required this.tasks});

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => const SizedBox();

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = tasks.where((task) => task['title'].toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(suggestions[index]['title']),
        onTap: () => close(context, suggestions[index]['title']),
      ),
    );
  }
}
