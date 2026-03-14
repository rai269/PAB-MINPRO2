import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Task> get inboxTasks => _tasks.where((t) => !t.archived).toList();

  List<Task> get todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return _tasks.where((t) {
      if (t.archived) return false;
      final d = DateTime(t.deadline.year, t.deadline.month, t.deadline.day);
      return !d.isBefore(today) && d.isBefore(tomorrow);
    }).toList();
  }

  List<Task> get upcomingTasks {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return _tasks.where((t) {
      if (t.archived) return false;
      final d = DateTime(t.deadline.year, t.deadline.month, t.deadline.day);
      return !d.isBefore(tomorrow);
    }).toList();
  }

  List<Task> get archivedTasks => _tasks.where((t) => t.archived).toList();

  List<Task> getTasksForDay(DateTime day) {
    return _tasks.where((t) {
      if (t.archived) return false;
      return t.deadline.year == day.year &&
          t.deadline.month == day.month &&
          t.deadline.day == day.day;
    }).toList();
  }

  // Notifikasi jangan sampai crash CRUD — selalu wrap terpisah
  Future<void> _safeSchedule(Task task) async {
    try {
      await NotificationService.scheduleTaskReminders(task);
    } catch (_) {}
  }

  Future<void> _safeCancel(String taskId) async {
    try {
      await NotificationService.cancelTaskReminders(taskId);
    } catch (_) {}
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await SupabaseService.fetchTasks();
      try {
        await NotificationService.rescheduleAll(_tasks);
      } catch (_) {} // notif error jangan crash load
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Task?> createTask(Task task) async {
    try {
      final created = await SupabaseService.createTask(task);
      _tasks.insert(0, created);
      notifyListeners();
      await _safeSchedule(created); // after notifyListeners, tidak block UI
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      final updated = await SupabaseService.updateTask(task);
      final idx = _tasks.indexWhere((t) => t.id == updated.id);
      if (idx != -1) _tasks[idx] = updated;
      notifyListeners();
      await _safeCancel(updated.id);
      await _safeSchedule(updated);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await SupabaseService.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
      await _safeCancel(id);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiveTask(Task task, {bool archive = true}) async {
    task.archived = archive;
    final ok = await updateTask(task);
    if (ok && archive) await _safeCancel(task.id);
    return ok;
  }

  Future<bool> toggleComplete(Task task) async {
    task.completed = !task.completed;
    final ok = await updateTask(task);
    if (ok && task.completed) await _safeCancel(task.id);
    return ok;
  }

  void clearTasks() {
    _tasks = [];
    notifyListeners();
  }
}
