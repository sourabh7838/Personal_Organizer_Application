import 'package:hive_flutter/hive_flutter.dart';
import '../../features/tasks/models/task.dart';
import '../../features/tasks/models/task_list.dart';

class HiveBoxes {
  static const String tasksBoxName = 'tasks';
  static const String taskListsBoxName = 'task_lists';
  static const String deletedTasksBoxName = 'deleted_tasks';
  
  static Box<Task>? _tasksBox;
  static Box<TaskList>? _taskListsBox;
  static Box<Task>? _deletedTasksBox;

  static Box<Task> get tasksBox {
    if (_tasksBox == null || !_tasksBox!.isOpen) {
      throw Exception('Tasks box is not initialized or was closed');
    }
    return _tasksBox!;
  }

  static Box<TaskList> get taskListsBox {
    if (_taskListsBox == null || !_taskListsBox!.isOpen) {
      throw Exception('Task lists box is not initialized or was closed');
    }
    return _taskListsBox!;
  }

  static Box<Task> get deletedTasksBox {
    if (_deletedTasksBox == null || !_deletedTasksBox!.isOpen) {
      throw Exception('Deleted tasks box is not initialized or was closed');
    }
    return _deletedTasksBox!;
  }

  static bool get isInitialized => 
    _tasksBox?.isOpen == true && 
    _taskListsBox?.isOpen == true && 
    _deletedTasksBox?.isOpen == true;

  static Future<void> init() async {
    if (isInitialized) return;

    // Register adapters first
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TaskListAdapter());
    }

    try {
      // Close boxes if they were open
      await closeBoxes();

      // Open boxes with improved compaction strategy
      _tasksBox = await Hive.openBox<Task>(
        tasksBoxName,
        compactionStrategy: (entries, deletedEntries) {
          return deletedEntries > 20 || deletedEntries / entries > 0.2;  // Compact when 20% of entries are deleted
        },
      );
      
      _taskListsBox = await Hive.openBox<TaskList>(
        taskListsBoxName,
        compactionStrategy: (entries, deletedEntries) {
          return deletedEntries > 10 || deletedEntries / entries > 0.2;
        },
      );
      
      _deletedTasksBox = await Hive.openBox<Task>(
        deletedTasksBoxName,
        compactionStrategy: (entries, deletedEntries) {
          return deletedEntries > 50 || entries > 1000;  // Keep deleted box from growing too large
        },
      );

      // Verify boxes are open
      if (!_tasksBox!.isOpen || !_taskListsBox!.isOpen || !_deletedTasksBox!.isOpen) {
        throw Exception('One or more boxes failed to open properly');
      }

      print('Hive boxes initialized successfully:');
      print('Tasks box: ${_tasksBox?.isOpen}, path: ${_tasksBox?.path}');
      print('Task lists box: ${_taskListsBox?.isOpen}, path: ${_taskListsBox?.path}');
      print('Deleted tasks box: ${_deletedTasksBox?.isOpen}, path: ${_deletedTasksBox?.path}');

      // Perform initial compaction
      await _tasksBox!.compact();
      await _taskListsBox!.compact();
      await _deletedTasksBox!.compact();
    } catch (e) {
      print("Error initializing Hive boxes: $e");
      // Try to clean up on error
      await closeBoxes();
      rethrow;
    }
  }

  static Future<void> closeBoxes() async {
    try {
      if (_tasksBox?.isOpen == true) await _tasksBox!.close();
      if (_taskListsBox?.isOpen == true) await _taskListsBox!.close();
      if (_deletedTasksBox?.isOpen == true) await _deletedTasksBox!.close();
    } finally {
      _tasksBox = null;
      _taskListsBox = null;
      _deletedTasksBox = null;
    }
  }
} 