import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../../../core/utils/hive_boxes.dart';
import '../providers/deleted_tasks_provider.dart';
import '../../../core/services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  late Box<Task> _tasksBox;
  late Box<TaskList> _taskListsBox;
  bool _isInitialized = false;
  final DeletedTasksProvider _deletedTasksProvider;
  final NotificationService _notificationService = NotificationService();

  TaskProvider({required DeletedTasksProvider deletedTasksProvider}) 
      : _deletedTasksProvider = deletedTasksProvider {
    _initBoxes();
  }

  Future<void> _initBoxes() async {
    if (_isInitialized) return;
    try {
      _tasksBox = HiveBoxes.tasksBox;
      _taskListsBox = HiveBoxes.taskListsBox;
      await _ensureDefaultListExists();
      _taskListsBox.listenable().addListener(notifyListeners);
      _tasksBox.listenable().addListener(notifyListeners);
      _isInitialized = true;
    } catch (e) {
      print("Error initializing boxes: $e");
      rethrow;
    }
  }

  List<TaskList> get taskLists => _taskListsBox.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  List<TaskList> get topLevelTaskLists => taskLists.where((list) => list.isTopLevel).toList();
  List<TaskList> getSubLists(String parentId) => taskLists.where((list) => list.parentId == parentId && !list.isCategoryOnly).toList();
  List<TaskList> getSubCategories(String parentId) => taskLists.where((list) => list.parentId == parentId && list.isCategoryOnly).toList();
  List<TaskList> getAllSubItems(String parentId) => taskLists.where((list) => list.parentId == parentId).toList();

  List<TaskList> get potentialParentCategories => taskLists.where((list) => list.isCategoryOnly).toList();
  List<TaskList> get assignableTaskLists => taskLists.where((list) => !list.isCategoryOnly).toList();

  TaskList? getTaskListById(String id) => _taskListsBox.get(id);

  Future<void> addTaskList(TaskList taskList) async {
    await _initBoxes();
    await _taskListsBox.put(taskList.id, taskList);
    notifyListeners();
  }

  Future<void> updateTaskList(TaskList list, {String? newName, String? newParentId}) async {
    await _initBoxes();
    bool changed = false;
    if (newName != null && list.name != newName) {
      list.name = newName;
      changed = true;
    }
    if (newParentId != list.id) {
      if (list.parentId != newParentId) {
        final newParent = newParentId != null ? getTaskListById(newParentId) : null;
        if (newParentId == null || (newParent != null && newParent.isCategoryOnly)) {
          list.parentId = newParentId;
          changed = true;
        }
      }
    }

    if (changed) {
      await list.save();
      notifyListeners();
    }
  }

  Future<void> deleteTaskList(String listId) async {
    await _initBoxes();
    final listToDelete = getTaskListById(listId);
    if (listToDelete == null) return;

    List<TaskList> descendants = [];
    List<String> toProcess = [listId];
    while(toProcess.isNotEmpty) {
      String currentParentId = toProcess.removeAt(0);
      List<TaskList> children = getAllSubItems(currentParentId);
      descendants.addAll(children);
      toProcess.addAll(children.map((c) => c.id));
    }

    try {
      // First handle all tasks in all descendant lists
      for (var descendant in descendants) {
        if (!descendant.isCategoryOnly) {
          final tasksInDescendant = _tasksBox.values.where((task) => task.taskListId == descendant.id).toList();
          for (var task in tasksInDescendant) {
            await deleteTask(task.id);  // Use the proper deleteTask method
          }
        }
      }

      // Then handle tasks in the list being deleted (if it's not a category)
      if (!listToDelete.isCategoryOnly) {
        final tasksInList = _tasksBox.values.where((task) => task.taskListId == listId).toList();
        for (var task in tasksInList) {
          await deleteTask(task.id);  // Use the proper deleteTask method
        }
      }

      // Finally delete all the lists/categories from bottom up
      for (var descendant in descendants.reversed) {
        await _taskListsBox.delete(descendant.id);
      }
      await _taskListsBox.delete(listId);
      
      notifyListeners();
    } catch (e) {
      print('Error during list deletion: $e');
      rethrow;
    }
  }

  List<Task> getTasksForList(String listId) {
    final list = getTaskListById(listId);
    if (list == null || list.isCategoryOnly) {
      return [];
    }
    return _tasksBox.values.where((task) => task.taskListId == listId).toList()
      ..sort((a, b) => (a.isCompleted ? 1:0).compareTo(b.isCompleted ? 1:0) == 0 
        ? a.createdAt.compareTo(b.createdAt) 
        : (a.isCompleted ? 1:0).compareTo(b.isCompleted ? 1:0));
  }

  Task? getTaskById(String id) => _tasksBox.get(id);

  Future<bool> addTask(Task task) async {
    await _initBoxes();
    try {
      await task.save();
      await _notificationService.scheduleTaskNotification(task);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error adding task: $e");
      return false;
    }
  }

  Future<void> updateTask(Task task) async {
    await _initBoxes();
    try {
      final existingTask = _tasksBox.get(task.id);
      if (existingTask == null) {
        throw Exception('Task not found');
      }
      await task.save();
      await _notificationService.scheduleTaskNotification(task);
      notifyListeners();
    } catch (e) {
      print("Error updating task: $e");
      rethrow;
    }
  }

  Future<void> updateTaskCompletion(String taskId, bool isCompleted) async {
    final task = _tasksBox.get(taskId);
    if (task != null) {
      task.isCompleted = isCompleted;
      await task.save();
      if (isCompleted) {
        await _notificationService.cancelNotification(taskId);
      } else {
        await _notificationService.scheduleTaskNotification(task);
      }
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompleted(String taskId) async {
    final task = _tasksBox.get(taskId);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      await task.save();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _initBoxes();
    try {
      print('Starting task deletion for ID: $taskId');
      
      // Verify box is open and accessible
      if (!_tasksBox.isOpen) {
        throw Exception('Tasks box is not open');
      }
      
      final task = _tasksBox.get(taskId);
      if (task == null) {
        print('Task not found for deletion: $taskId');
        return;
      }

      // Create a copy for the deleted tasks
      final taskCopy = Task(
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

      try {
        // First add to deleted tasks
        await _deletedTasksProvider.addToDeleted(taskCopy);

        // Then delete from main box
        await _tasksBox.delete(taskId);
        await _tasksBox.compact();  // Compact to remove deleted entries
        await _tasksBox.flush();    // Ensure changes are written to disk
        
        // Verify deletion
        if (_tasksBox.containsKey(taskId)) {
          throw Exception('Task still exists after deletion attempt');
        }

        print('Task successfully deleted and moved to deleted box: $taskId');
        notifyListeners();
      } catch (e) {
        print('Error during task deletion process: $e');
        // Try to rollback the deletion from deleted tasks box if main deletion failed
        try {
          await _deletedTasksProvider.restoreTask(taskId);
        } catch (rollbackError) {
          print('Error during deletion rollback: $rollbackError');
        }
        rethrow;
      }
    } catch (e) {
      print('Error during task deletion: $e');
      rethrow;
    }
  }

  Future<void> toggleTaskStar(String taskId) async {
    final task = _tasksBox.get(taskId);
    if (task != null) {
      task.isStarred = !task.isStarred;
      await task.save();
      notifyListeners();
    }
  }

  List<Task> get starredTasks =>
      _tasksBox.values.where((task) => task.isStarred).toList()
        ..sort((a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0) == 0
            ? a.createdAt.compareTo(b.createdAt)
            : (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0));

  List<Task> get todaysTasks {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return _tasksBox.values.where((task) =>
    task.dueDate != null && !task.dueDate!.isBefore(todayStart) && task.dueDate!.isBefore(todayEnd))
        .toList()..sort((a,b) => (a.dueDate!).compareTo(b.dueDate!));
  }

  List<Task> get thisWeeksTasks {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    final todayStart = DateTime(now.year, now.month, now.day);
    final startOfWeek = todayStart.subtract(Duration(days: dayOfWeek - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));

    return _tasksBox.values.where((task) =>
    task.dueDate != null &&
        !task.dueDate!.isBefore(startOfWeek) &&
        task.dueDate!.isBefore(endOfWeek.add(const Duration(microseconds: 1)))
    ).toList()..sort((a,b) => (a.dueDate!).compareTo(b.dueDate!));
  }

  List<Task> get allTasks => _tasksBox.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> _ensureDefaultListExists() async {
    if (assignableTaskLists.isEmpty) {
      final defaultTaskList = TaskList(id: "default_tasks_list_main", name: "My Tasks", isCategoryOnly: false);
      await _taskListsBox.put(defaultTaskList.id, defaultTaskList);
    }
  }
} 