import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/ui_helpers.dart';
import '../widgets/task_card.dart';
import 'task_form_page.dart';
import 'task_detail_page.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  String _searchQuery = '';
  bool _showSearch = false;

  Future<void> _confirmDelete(Task task) async {
    hapticMedium();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tugas'),
        content: Text('Yakin ingin menghapus "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await context.read<TaskProvider>().deleteTask(task.id);
    showSnack(context, ok ? 'Tugas dihapus' : 'Gagal menghapus', isError: !ok,
        icon: ok ? Icons.delete_outline_rounded : null);
  }

  Future<void> _archive(Task task) async {
    final ok = await context.read<TaskProvider>().archiveTask(task, archive: true);
    showSnack(context, ok ? 'Dipindahkan ke arsip' : 'Gagal mengarsipkan',
        isError: !ok, icon: Icons.inventory_2_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final allTasks = provider.inboxTasks;
    final tasks = _searchQuery.isEmpty
        ? allTasks
        : allTasks.where((t) =>
            t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Inbox'),
            actions: [
              IconButton(
                icon: Icon(_showSearch ? Icons.search_off : Icons.search),
                onPressed: () {
                  hapticLight();
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) _searchQuery = '';
                  });
                },
              ),
            ],
            bottom: _showSearch
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Cari tugas...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  )
                : null,
          ),
        ],
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => context.read<TaskProvider>().loadTasks(),
                child: tasks.isEmpty
                    ? _EmptyState(
                        icon: Icons.inbox_outlined,
                        title: _searchQuery.isNotEmpty ? 'Tidak ditemukan' : 'Inbox kosong',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'Coba kata kunci lain'
                            : 'Tap + untuk menambah tugas baru',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) {
                          final task = tasks[i];
                          return TaskCard(
                            task: task,
                            onTap: () {
                              hapticLight();
                              Navigator.push(ctx, smoothRoute(TaskDetailPage(task: task)));
                            },
                            onDelete: () => _confirmDelete(task),
                            onEdit: () => Navigator.push(
                                ctx, smoothRoute(TaskFormPage(task: task))),
                            onArchive: () => _archive(task),
                            onToggleComplete: () {
                              hapticSelect();
                              context.read<TaskProvider>().toggleComplete(task);
                            },
                          );
                        },
                      ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          hapticLight();
          Navigator.push(context, smoothRoute(const TaskFormPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w600)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
