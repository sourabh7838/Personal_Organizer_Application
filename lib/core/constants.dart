/// Breakpoints for responsive design
class Breakpoints {
  static const double tablet = 720.0;
  static const double desktop = 1100.0;
}

/// Spacing constants for consistent padding and margins
class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// Animation durations
class Durations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
}

/// Hive storage constants
class HiveConstants {
  static const String tasksBoxName = 'tasks';
  static const String taskListsBoxName = 'task_lists';
}

/// App-wide string constants
class Strings {
  static const String appName = 'Personal Organizer';
  static const String version = '1.1.0';
  
  // Navigation
  static const String allTasks = 'All Tasks';
  static const String starred = 'Starred';
  static const String today = 'Today';
  static const String thisWeek = 'This Week';
  static const String categories = 'MY CATEGORIES & LISTS';
  
  // Actions
  static const String addTask = 'Add Task';
  static const String editTask = 'Edit Task';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  
  // Messages
  static const String noTasks = 'No tasks yet. Add some!';
  static const String noStarredTasks = 'No starred tasks yet.';
  static const String noTasksToday = 'No tasks due today.';
  static const String noTasksThisWeek = 'No tasks due this week.';
  static const String welcome = 'Welcome!';
  static const String getStarted = 'Create a category (e.g., \'Personal\') or a list to get started.';
} 