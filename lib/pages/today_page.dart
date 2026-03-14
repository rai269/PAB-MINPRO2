import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/ui_helpers.dart';
import '../widgets/task_card.dart';
import 'task_form_page.dart';
import 'task_detail_page.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    hapticMedium();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tugas'),
        content: Text('Yakin menghapus "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await context.read<TaskProvider>().deleteTask(task.id);
    showSnack(context, ok ? 'Tugas dihapus' : 'Gagal menghapus', isError: !ok);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.todayTasks;
    final done = tasks.where((t) => t.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hari Ini'),
        bottom: tasks.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: LinearProgressIndicator(
                  value: tasks.isEmpty ? 0 : done / tasks.length,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  color: Colors.green,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<TaskProvider>().loadTasks(),
        child: tasks.isEmpty
            ? const _EmptyState(
                icon: Icons.wb_sunny_outlined,
                title: 'Tidak ada tugas hari ini',
                subtitle: 'Selamat, semua beres! 🎉',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: tasks.length,
                itemBuilder: (ctx, i) {
                  final task = tasks[i];
                  return TaskCard(
                    task: task,
                    onTap: () { hapticLight(); Navigator.push(ctx, smoothRoute(TaskDetailPage(task: task))); },
                    onDelete: () => _confirmDelete(context, task),
                    onEdit: () => Navigator.push(ctx, smoothRoute(TaskFormPage(task: task))),
                    onArchive: () => context.read<TaskProvider>().archiveTask(task, archive: true),
                    onToggleComplete: () { hapticSelect(); context.read<TaskProvider>().toggleComplete(task); },
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 72, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
