import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/ui_helpers.dart';
import '../widgets/task_card.dart';
import 'task_detail_page.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    hapticMedium();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Permanen'),
        content: Text('Yakin menghapus "${task.title}" secara permanen?'),
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
    showSnack(context, ok ? 'Tugas dihapus permanen' : 'Gagal menghapus', isError: !ok);
  }

  Future<void> _unarchive(BuildContext context, Task task) async {
    final ok = await context.read<TaskProvider>().archiveTask(task, archive: false);
    showSnack(context, ok ? 'Dipindahkan ke inbox' : 'Gagal', isError: !ok,
        icon: Icons.inbox_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.archivedTasks;

    return Scaffold(
      appBar: AppBar(title: const Text('Arsip')),
      body: RefreshIndicator(
        onRefresh: () => context.read<TaskProvider>().loadTasks(),
        child: tasks.isEmpty
            ? const _EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Arsip kosong',
                subtitle: 'Tugas yang diarsipkan akan muncul di sini',
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
                    onEdit: () => Navigator.push(ctx, smoothRoute(TaskDetailPage(task: task))),
                    onArchive: () => _unarchive(context, task),
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
