import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onEdit,
    this.onArchive,
    this.onToggleComplete,
    this.onTap,
  });

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high': return 'Tinggi';
      case 'medium': return 'Sedang';
      case 'low': return 'Rendah';
      default: return priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = !task.completed && task.deadline.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onToggleComplete != null)
                    GestureDetector(
                      onTap: onToggleComplete,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.completed
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: task.completed
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: task.completed
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                  if (onToggleComplete != null) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                        color: task.completed ? Colors.grey : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _priorityColor(task.priority).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _priorityLabel(task.priority),
                      style: TextStyle(
                        fontSize: 11,
                        color: _priorityColor(task.priority),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14,
                          color: isOverdue ? Colors.red : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(task.deadline),
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey,
                          fontSize: 12,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      if (onArchive != null)
                        IconButton(
                          icon: Icon(
                            task.archived
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                            size: 20,
                          ),
                          onPressed: onArchive,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
