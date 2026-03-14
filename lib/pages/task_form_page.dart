import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/ui_helpers.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/supabase_service.dart';

class TaskFormPage extends StatefulWidget {
  final Task? task;

  const TaskFormPage({super.key, this.task});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _deadlineController = TextEditingController();

  DateTime? _selectedDate;
  String _priority = 'medium';
  bool _isLoading = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _selectedDate = widget.task!.deadline;
      _deadlineController.text =
          DateFormat('dd MMM yyyy').format(widget.task!.deadline);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _deadlineController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<TaskProvider>();

    try {
      if (_isEditing) {
        widget.task!.title = _titleController.text.trim();
        widget.task!.description = _descController.text.trim();
        widget.task!.priority = _priority;
        widget.task!.deadline = _selectedDate ?? DateTime.now();

        final ok = await provider.updateTask(widget.task!);
        if (mounted) {
          showSnack(context, ok ? 'Tugas berhasil diperbarui' : 'Gagal memperbarui tugas', isError: !ok);
          if (ok) Navigator.pop(context, widget.task);
        }
      } else {
        final userId = SupabaseService.currentUser!.id;
        final newTask = Task(
          id: '',
          userId: userId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          priority: _priority,
          deadline: _selectedDate ?? DateTime.now(),
          createdAt: DateTime.now(),
        );

        final created = await provider.createTask(newTask);
        if (mounted) {
          showSnack(context, created != null ? 'Tugas berhasil ditambahkan' : 'Gagal menambahkan tugas', isError: created == null);
          if (created != null) Navigator.pop(context, created);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tugas' : 'Tambah Tugas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Judul wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi *',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Deadline *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Deadline wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Prioritas *',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _PrioritySelector(
                selected: _priority,
                onChanged: (v) => setState(() => _priority = v),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_isEditing ? 'Perbarui' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PrioritySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      {'value': 'low', 'label': 'Rendah', 'color': Colors.green},
      {'value': 'medium', 'label': 'Sedang', 'color': Colors.orange},
      {'value': 'high', 'label': 'Tinggi', 'color': Colors.red},
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt['value'];
        final color = opt['color'] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isSelected ? Icons.flag : Icons.flag_outlined,
                    color: isSelected ? color : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? color : Colors.grey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
