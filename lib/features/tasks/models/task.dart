import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/hive_boxes.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

/// Represents a task in the application.
/// 
/// A task is the basic unit of work that can be tracked, managed, and organized
/// within the application. Tasks can be assigned priorities, due dates, and can
/// be marked as completed or starred for importance.
@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  /// The title or name of the task
  @HiveField(1)
  String title;

  /// Optional detailed description of the task
  @HiveField(2)
  String? description;

  /// Whether the task has been completed
  @HiveField(3)
  bool isCompleted;

  /// Whether the task is marked as important/starred
  @HiveField(4)
  bool isStarred;

  /// The priority level of the task
  @HiveField(5)
  Priority priority;

  /// ID of the list this task belongs to
  @HiveField(6)
  String taskListId;

  /// Optional due date for the task
  @HiveField(7)
  DateTime? dueDate;

  /// When the task was created
  @HiveField(8)
  final DateTime createdAt;

  Task({
    String? id,
    required this.title,
    this.description,
    bool? isCompleted,
    bool? isStarred,
    Priority? priority,
    required this.taskListId,
    this.dueDate,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       isCompleted = isCompleted ?? false,
       isStarred = isStarred ?? false,
       priority = priority ?? Priority.medium,
       createdAt = createdAt ?? DateTime.now();

  Box<Task> get _box => Hive.box<Task>(HiveBoxes.tasksBoxName);

  @override
  Future<void> save() async {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.tasksBoxName)) {
        throw Exception('Tasks box is not open');
      }
      await _box.put(id, this);
      await _box.flush();
      print('Task saved successfully: $id');
    } catch (e) {
      print("Error saving task: $e");
      rethrow;
    }
  }

  @override
  Future<void> delete() async {
    throw UnimplementedError('Task deletion should be handled through TaskProvider');
  }

  Task clone() {
    return Task(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      isStarred: isStarred,
      priority: priority,
      taskListId: taskListId,
      dueDate: dueDate,
      createdAt: createdAt,
    );
  }

  /// Creates a copy of this task with the given fields replaced with new values
  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    bool? isStarred,
    Priority? priority,
    String? taskListId,
    DateTime? dueDate,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isStarred: isStarred ?? this.isStarred,
      priority: priority ?? this.priority,
      taskListId: taskListId ?? this.taskListId,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
    );
  }
} 