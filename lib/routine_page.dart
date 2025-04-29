import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  Map<String, List<Map<String, dynamic>>> tasksPerHour = {};
  bool isDayView = true; // Future: toggle to week view

 final List<String> hours = List.generate(
  21, 
  (index) {
    int hour24 = index + 4; // 4 AM start
    String period = hour24 >= 12 ? "PM" : "AM";
    int hour12 = hour24 > 12 ? hour24 - 12 : hour24;
    if (hour12 == 0) hour12 = 12;
    return "$hour12 $period";
  }
);


  @override
  void initState() {
    super.initState();
    _loadRoutine();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentHour();
    });
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToCurrentHour() {
    final now = DateTime.now();
    int hourIndex = now.hour - 6;
    if (hourIndex >= 0 && hourIndex < hours.length) {
      _scrollController.jumpTo(hourIndex * 120); // Each card approx 120px tall
    }
  }

  Future<void> _loadRoutine() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('routine');
    if (saved != null) {
      setState(() {
        tasksPerHour = Map<String, List<Map<String, dynamic>>>.from(
          jsonDecode(saved).map((key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value))),
        );
      });
    }
  }

  Future<void> _saveRoutine() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('routine', jsonEncode(tasksPerHour));
  }

  void _addTaskDialog(String hour) {
    final TextEditingController _taskController = TextEditingController();
    final TextEditingController _noteController = TextEditingController();
    String color = "Blue";
    int duration = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskController,
                decoration: const InputDecoration(hintText: "Task Title"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(hintText: "Notes (optional)"),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: color,
                isExpanded: true,
                onChanged: (val) => setModalState(() => color = val!),
                items: ["Blue", "Green", "Red", "Yellow"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              ),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: duration,
                isExpanded: true,
                onChanged: (val) => setModalState(() => duration = val!),
                items: [1, 2, 3, 4].map((e) => DropdownMenuItem(value: e, child: Text("$e hour(s)"))).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_taskController.text.trim().isNotEmpty) {
                    setState(() {
                      tasksPerHour.putIfAbsent(hour, () => []);
                      tasksPerHour[hour]!.add({
                        "title": _taskController.text.trim(),
                        "note": _noteController.text.trim(),
                        "color": color,
                        "duration": duration,
                        "completed": false,
                      });
                    });
                    _saveRoutine();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Add Task"),
              ),
              const SizedBox(height: 10),
            ],
          );
        }),
      ),
    );
  }

  Color _getColor(String color) {
    switch (color) {
      case "Red":
        return Colors.red;
      case "Green":
        return Colors.green;
      case "Yellow":
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView.builder(
        controller: _scrollController,
        itemCount: hours.length,
        itemBuilder: (context, index) {
          final hour = hours[index];
          final isCurrentHour = DateTime.now().hour == index + 6;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: isCurrentHour ? Colors.teal[100] : Colors.grey[200],
              child: ExpansionTile(
                initiallyExpanded: isCurrentHour,
                title: Text(hour, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                children: [
                  ...(tasksPerHour[hour] ?? []).asMap().entries.map((entry) {
                    int taskIndex = entry.key;
                    Map<String, dynamic> task = entry.value;
                    return Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        setState(() {
                          tasksPerHour[hour]!.removeAt(taskIndex);
                        });
                        _saveRoutine();
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColor(task['color']),
                          child: Icon(
                            task['completed'] ? Icons.check : Icons.radio_button_unchecked,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(task['title']),
                        subtitle: Text(task['note']),
                        trailing: Checkbox(
                          value: task['completed'],
                          onChanged: (val) {
                            setState(() {
                              task['completed'] = val!;
                            });
                            _saveRoutine();
                          },
                        ),
                        onTap: () {
                          _addTaskDialog(hour); // Future: edit on tap
                        },
                      ),
                    );
                  }).toList(),
                  TextButton.icon(
                    onPressed: () => _addTaskDialog(hour),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Add Task"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => isDayView = !isDayView),
        child: const Icon(Icons.swap_horiz),
        tooltip: "Switch Day/Week View (future)",
      ),
    );
  }
}
