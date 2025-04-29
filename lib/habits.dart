import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  List<Map<String, dynamic>> habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
    _updateDailyStreaks();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('habits');
    if (saved != null) {
      setState(() {
        habits = List<Map<String, dynamic>>.from(jsonDecode(saved));
      });
    }
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('habits', jsonEncode(habits));
  }

  void _toggleCompletion(int index) {
    setState(() {
      habits[index]['completedToday'] = !(habits[index]['completedToday'] ?? false);
    });
    _saveHabits();
  }

  void _updateDailyStreaks() {
    final today = DateTime.now();
    for (var habit in habits) {
      final lastCheckedStr = habit['lastChecked'] ?? '';
      final lastChecked = lastCheckedStr.isNotEmpty ? DateTime.parse(lastCheckedStr) : null;
      final freq = habit['frequency'];

      bool shouldCount = false;
      if (lastChecked == null || !_isSamePeriod(today, lastChecked, freq)) {
        shouldCount = true;
      }

      if (shouldCount) {
        if (habit['type'] == 'Good') {
          if (habit['completedToday'] == true) {
            habit['streak'] = (habit['streak'] ?? 0) + 1;
          } else {
            habit['streak'] = 0;
          }
        } else {
          if (habit['completedToday'] == true) {
            habit['streak'] = 0;
          } else {
            habit['streak'] = (habit['streak'] ?? 0) + 1;
          }
        }
        habit['completedToday'] = false;
        habit['lastChecked'] = today.toIso8601String();
      }
    }
    _saveHabits();
  }

  bool _isSamePeriod(DateTime a, DateTime b, String freq) {
    if (freq == 'Daily') {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    } else if (freq == 'Weekly') {
      return a.difference(b).inDays < 7 && a.weekday >= b.weekday;
    } else if (freq == 'Monthly') {
      return a.year == b.year && a.month == b.month;
    }
    return false;
  }

  void _addOrEditHabitDialog({Map<String, dynamic>? existingHabit, int? index}) {
    final nameController = TextEditingController(text: existingHabit?['name'] ?? '');
    final noteController = TextEditingController(text: existingHabit?['note'] ?? '');
    String type = existingHabit?['type'] ?? "Good";
    String frequency = existingHabit?['frequency'] ?? "Daily";
    bool reminder = existingHabit?['reminder'] ?? false;
    int goal = existingHabit?['goal'] ?? 30;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text("Habit Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            if (nameController.text.isNotEmpty) {
                              setState(() {
                                final newHabit = {
                                  "name": nameController.text,
                                  "type": type,
                                  "frequency": frequency,
                                  "reminder": reminder,
                                  "note": noteController.text,
                                  "goal": goal,
                                  "streak": existingHabit?['streak'] ?? 0,
                                  "completedToday": existingHabit?['completedToday'] ?? false,
                                  "lastChecked": existingHabit?['lastChecked'] ?? ""
                                };
                                if (index != null) {
                                  habits[index] = newHabit;
                                } else {
                                  habits.add(newHabit);
                                }
                              });
                              _saveHabits();
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Habit Name"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: "Habit Note"),
                    ),
                    const SizedBox(height: 10),
                    ToggleButtons(
                      isSelected: [type == "Good", type == "Bad"],
                      onPressed: (index) => setModalState(() => type = index == 0 ? "Good" : "Bad"),
                      children: const [Text("Good"), Text("Bad")],
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: frequency,
                      isExpanded: true,
                      onChanged: (value) => setModalState(() => frequency = value!),
                      items: const [
                        DropdownMenuItem(value: "Daily", child: Text("Daily")),
                        DropdownMenuItem(value: "Weekly", child: Text("Weekly")),
                        DropdownMenuItem(value: "Monthly", child: Text("Monthly")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Goal Days: "),
                        Expanded(
                          child: Slider(
                            value: goal.toDouble(),
                            min: 1,
                            max: 100,
                            divisions: 99,
                            label: "$goal days",
                            onChanged: (val) => setModalState(() => goal = val.toInt()),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text("Enable Reminder"),
                      value: reminder,
                      onChanged: (val) => setModalState(() => reminder = val),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedHabits = List<Map<String, dynamic>>.from(habits)
      ..sort((a, b) => a['type'].compareTo(b['type']));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: sortedHabits.length,
          itemBuilder: (context, index) {
            final habit = sortedHabits[index];
            final streakPercent = ((habit['streak'] ?? 0) / (habit['goal'] ?? 30)).clamp(0, 1).toDouble();
            final isGood = habit['type'] == "Good";

            return Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                final removedHabit = habits.removeAt(habits.indexOf(habit));
                _saveHabits();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Deleted '${removedHabit['name']}'"),
                    action: SnackBarAction(
                      label: "Undo",
                      onPressed: () {
                        setState(() {
                          habits.add(removedHabit);
                        });
                        _saveHabits();
                      },
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: isGood ? Colors.green[50] : Colors.red[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isGood ? Colors.green : Colors.red,
                    child: Text(
                      "${habit['streak'] ?? 0}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    habit['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit['note'] ?? "", style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: streakPercent,
                        backgroundColor: Colors.grey[300],
                        color: isGood ? Colors.green : Colors.red,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Freq: ${habit['frequency']} | Goal: ${habit['goal']} days",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      habit['completedToday'] ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: habit['completedToday'] ? Colors.teal : Colors.grey,
                    ),
                    onPressed: () => _toggleCompletion(habits.indexOf(habit)),
                    tooltip: "Mark Today",
                  ),
                  onLongPress: () => _addOrEditHabitDialog(existingHabit: habit, index: habits.indexOf(habit)),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditHabitDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
