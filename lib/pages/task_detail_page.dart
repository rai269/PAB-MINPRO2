import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_form_page.dart';

class TaskDetailPage extends StatelessWidget {
  final Task task;

  const TaskDetailPage({super.key, required this.task});

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'high':
        return 'Tinggi';
      case 'medium':
        return 'Sedang';
      default:
        return 'Rendah';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskFormPage(task: task),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _priorityLabel(task.priority),
                    style: TextStyle(
                      color: _priorityColor(task.priority),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Deadline',
              value: DateFormat('dd MMMM yyyy').format(task.deadline),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.check_circle_outline,
              label: 'Status',
              value: task.completed ? 'Selesai' : 'Belum Selesai',
              valueColor: task.completed ? Colors.green : Colors.orange,
            ),
            const Divider(height: 32),
            Text(
              'Deskripsi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              task.description.isEmpty ? '-' : task.description,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                context.read<TaskProvider>().toggleComplete(task);
                Navigator.pop(context);
              },
              icon: Icon(
                task.completed ? Icons.undo : Icons.check_circle_outline,
              ),
              label: Text(
                task.completed
                    ? 'Tandai Belum Selesai'
                    : 'Tandai Selesai',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: cs.primary),
                foregroundColor: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
