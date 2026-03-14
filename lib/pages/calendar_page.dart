import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final selectedTasks =
        _selectedDay == null ? <Task>[] : provider.getTasksForDay(_selectedDay!);

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<Task>(
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2100),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  eventLoader: provider.getTasksForDay,
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _selectedDay == null
                      ? const Center(
                          child: Text('Tap tanggal untuk melihat tugas'),
                        )
                      : selectedTasks.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada tugas pada\n${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: selectedTasks.length,
                          itemBuilder: (ctx, i) {
                            final task = selectedTasks[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              leading: CircleAvatar(
                                backgroundColor: task.completed
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.primary,
                                child: Icon(
                                  task.completed
                                      ? Icons.check
                                      : Icons.task_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: task.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                task.priority == 'high'
                                    ? 'Prioritas Tinggi'
                                    : task.priority == 'medium'
                                    ? 'Prioritas Sedang'
                                    : 'Prioritas Rendah',
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TaskDetailPage(task: task),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
