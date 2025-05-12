import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/hive_boxes.dart';
import '../models/task.dart';

class DeletedTasksProvider extends ChangeNotifier {
  Box<Task>? _deletedTasksBox;
  bool _isInitialized = false;

  static Future<DeletedTasksProvider> create() async {
    final provider = DeletedTasksProvider._();
    await provider._ensureInitialized();
    return provider;
  }

  DeletedTasksProvider._();

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        if (!HiveBoxes.isInitialized) {
          throw Exception('Hive boxes are not initialized');
        }
        _deletedTasksBox = HiveBoxes.deletedTasksBox;
        _isInitialized = true;
      } catch (e) {
        print('Error initializing deleted tasks box: $e');
        rethrow;
      }
    }
  }

  List<Task> get deletedTasks {
    if (!_isInitialized) return [];
    return _deletedTasksBox?.values.toList() ?? []
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addToDeleted(Task task) async {
    await _ensureInitialized();
    try {
      if (_deletedTasksBox == null) {
        throw Exception('Deleted tasks box is not initialized');
      }
      await _deletedTasksBox!.put(task.id, task);
      await _deletedTasksBox!.compact();
      notifyListeners();
    } catch (e) {
      print('Error adding task to deleted box: $e');
      rethrow;
    }
  }

  Future<Task?> restoreTask(String taskId) async {
    await _ensureInitialized();
    try {
      if (_deletedTasksBox == null) {
        throw Exception('Deleted tasks box is not initialized');
      }
      final task = _deletedTasksBox!.get(taskId);
      if (task != null) {
        final restoredTask = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          isCompleted: task.isCompleted,
          isStarred: task.isStarred,
          priority: task.priority,
          taskListId: task.taskListId,
          dueDate: task.dueDate,
          createdAt: task.createdAt,
        );
        await _deletedTasksBox!.delete(taskId);
        await _deletedTasksBox!.compact();
        notifyListeners();
        return restoredTask;
      }
      return null;
    } catch (e) {
      print('Error restoring task: $e');
      rethrow;
    }
  }

  Future<void> clearDeleted() async {
    await _ensureInitialized();
    try {
      if (_deletedTasksBox == null) {
        throw Exception('Deleted tasks box is not initialized');
      }
      await _deletedTasksBox!.clear();
      await _deletedTasksBox!.compact();
      notifyListeners();
    } catch (e) {
      print('Error clearing deleted tasks: $e');
      rethrow;
    }
  }
} 