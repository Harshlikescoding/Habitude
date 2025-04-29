import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  DateTime selectedMonth = DateTime.now();

  int completed = 20;
  int missed = 10;
  int longestStreak = 12;

  List<Map<String, dynamic>> categories = [
    {"name": "Health", "count": 12},
    {"name": "Productivity", "count": 8},
    {"name": "Bad Habits Broken", "count": 10},
  ];

  void _changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<int> days = List.generate(30, (i) => i + 1);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat("MMMM yyyy").format(selectedMonth),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: days.map((d) {
                  return Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: d % 2 == 0 ? Colors.teal : Colors.grey[700],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text("$d", style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text("Statistics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox("Completed", completed, Colors.green),
                  _statBox("Missed", missed, Colors.red),
                  _statBox("Streak", longestStreak, Colors.orange),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Category Breakdown", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: categories.map((c) => PieChartSectionData(
                      title: c['name'],
                      value: c['count'].toDouble(),
                      color: c['name'] == "Health"
                          ? Colors.green
                          : c['name'] == "Productivity"
                              ? Colors.blue
                              : Colors.red,
                      radius: 50,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Highlights", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _highlightCard("Best Habit", "Gym - 15 completions!", Icons.fitness_center, Colors.green),
              const SizedBox(height: 10),
              _highlightCard("Needs Focus", "Reading - 5 misses", Icons.menu_book, Colors.red),
              const SizedBox(height: 20),
              const Text("Motivation", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _quoteCard("Every small progress counts. Keep pushing forward!")
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text("$value", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _highlightCard(String title, String desc, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
      ),
    );
  }

  Widget _quoteCard(String quote) {
    return Card(
      color: Colors.teal[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.format_quote, size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text(quote, style: const TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
}
