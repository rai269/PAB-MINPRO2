class Task {
  final String id;
  final String userId;
  String title;
  String description;
  String priority;
  DateTime deadline;
  bool completed;
  bool archived;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.deadline,
    this.completed = false,
    this.archived = false,
    required this.createdAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'medium',
      deadline: DateTime.parse(map['deadline'] as String).toLocal(),
      completed: map['completed'] as bool? ?? false,
      archived: map['archived'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  // Untuk INSERT (include user_id)
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'priority': priority,
      'deadline': deadline.toUtc().toIso8601String(), // UTC agar Supabase happy
      'completed': completed,
      'archived': archived,
    };
  }

  // Untuk UPDATE (jangan include user_id — hindari RLS conflict)
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'deadline': deadline.toUtc().toIso8601String(),
      'completed': completed,
      'archived': archived,
    };
  }
}
