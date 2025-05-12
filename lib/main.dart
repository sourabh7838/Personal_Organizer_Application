import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';

import 'core/utils/hive_boxes.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/services/notification_service.dart';
import 'features/tasks/models/task.dart';
import 'features/tasks/models/task_list.dart';
import 'features/tasks/providers/deleted_tasks_provider.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/tasks/screens/deleted_tasks_screen.dart';
import 'features/tasks/widgets/task_tile.dart';

// --- CORE (Theme) ---
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1C1B1F),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      enableFeedback: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.grey[100],
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      enableFeedback: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

// --- WIDGETS ---
const double kTabletBreakpoint = 720.0;
const double kDesktopBreakpoint = 1100.0;

class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobileBuilder;
  final Widget Function(BuildContext context)? tabletBuilder;
  final Widget Function(BuildContext context)? desktopBuilder;

  const ResponsiveLayoutBuilder({super.key, required this.mobileBuilder, this.tabletBuilder, this.desktopBuilder});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= kDesktopBreakpoint && desktopBuilder != null) return desktopBuilder!(context);
      if (constraints.maxWidth >= kTabletBreakpoint && tabletBuilder != null) return tabletBuilder!(context);
      return mobileBuilder(context);
    },
  );
}

class FilteredTasksView extends StatefulWidget {
  final String viewTitle;
  final List<Task> tasks;
  final IconData? headerIcon;
  final String? emptyMessage;
  final String? associatedListIdForAdd;
  final String currentSearchQuery;

  const FilteredTasksView({
    super.key,
    required this.viewTitle,
    required this.tasks,
    this.headerIcon,
    this.emptyMessage,
    this.associatedListIdForAdd,
    required this.currentSearchQuery,
  });

  @override
  State<FilteredTasksView> createState() => _FilteredTasksViewState();
}

class _FilteredTasksViewState extends State<FilteredTasksView> {
  List<Task> _incompleteTasks = [];
  List<Task> _completedTasks = [];

  @override
  void initState() {
    super.initState();
    _updateTaskLists();
  }

  @override
  void didUpdateWidget(FilteredTasksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks) {
      _updateTaskLists();
    }
  }

  void _updateTaskLists() {
    if (!mounted) return;
    setState(() {
      _incompleteTasks = widget.tasks.where((task) => !task.isCompleted).toList();
      _completedTasks = widget.tasks.where((task) => task.isCompleted).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    String effectiveEmptyMessage = widget.emptyMessage ?? 'No tasks found for "${widget.viewTitle}".';
    if (widget.currentSearchQuery.isNotEmpty && widget.tasks.isEmpty) {
      effectiveEmptyMessage = 'No tasks match "${widget.currentSearchQuery}" in "${widget.viewTitle}".';
    }

    if (_incompleteTasks.isEmpty && _completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.headerIcon ?? Icons.task_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              effectiveEmptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        if (_incompleteTasks.isNotEmpty) 
          ..._incompleteTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: TaskTile(
                key: ValueKey("task_${task.id}"),
                task: task,
                onDeleted: () {
                  setState(() {
                    _incompleteTasks.removeWhere((t) => t.id == task.id);
                  });
                },
              ),
            ),
          ),
        if (_completedTasks.isNotEmpty && _incompleteTasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[400])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[400])),
              ],
            ),
          ),
        if (_completedTasks.isNotEmpty)
          ..._completedTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: TaskTile(
                key: ValueKey("task_${task.id}"),
                task: task,
                onDeleted: () {
                  setState(() {
                    _completedTasks.removeWhere((t) => t.id == task.id);
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}

// --- SCREENS ---
enum AppViewType { taskList, category, starred, today, thisWeek, allTasks } // Added 'category'

class AddEditTaskScreen extends StatefulWidget {
  final Task? taskToEdit;
  final String taskListId; // This should always be an ID of a list where isCategoryOnly = false

  const AddEditTaskScreen({super.key, this.taskToEdit, required this.taskListId});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController, _descriptionController;
  late bool _isCompleted, _isStarred;
  DateTime? _dueDate;
  Priority _priority = Priority.medium;
  late String _selectedTaskListId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.taskToEdit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.taskToEdit?.description ?? '');
    _isCompleted = widget.taskToEdit?.isCompleted ?? false;
    _isStarred = widget.taskToEdit?.isStarred ?? false;
    _dueDate = widget.taskToEdit?.dueDate;
    _priority = widget.taskToEdit?.priority ?? Priority.medium;
    _selectedTaskListId = widget.taskToEdit?.taskListId ?? widget.taskListId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      // Ensure the selectedTaskListId is valid and not a category-only list
      if (!taskProvider.assignableTaskLists.any((list) => list.id == _selectedTaskListId) &&
          taskProvider.assignableTaskLists.isNotEmpty) {
        setState(() => _selectedTaskListId = taskProvider.assignableTaskLists.first.id);
      } else if (taskProvider.assignableTaskLists.isEmpty) {
        // Handle case where no assignable lists exist (should be rare due to provider's default list creation)
        print("Error: No assignable lists available for task.");
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()));
      if (pickedTime != null && mounted) {
        setState(() => _dueDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
      }
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Ensure selected list exists and is not category-only
    final listForTask = taskProvider.getTaskListById(_selectedTaskListId);
    if (listForTask == null) {
      // The list was deleted while editing, show error and redirect to first available list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The selected list no longer exists."), backgroundColor: Colors.red)
      );
      if (taskProvider.assignableTaskLists.isNotEmpty) {
        setState(() => _selectedTaskListId = taskProvider.assignableTaskLists.first.id);
      }
      return;
    }

    if (listForTask.isCategoryOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot save task: Selected item is a category, not a list."), backgroundColor: Colors.red)
      );
      return;
    }

    if (taskProvider.assignableTaskLists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot save: No lists available to add tasks."), backgroundColor: Colors.red)
      );
      return;
    }

    _formKey.currentState!.save();

    bool success = false;
    if (widget.taskToEdit != null) {
      try {
        widget.taskToEdit!.title = _titleController.text;
        widget.taskToEdit!.description = _descriptionController.text;
        widget.taskToEdit!.isCompleted = _isCompleted;
        widget.taskToEdit!.isStarred = _isStarred;
        widget.taskToEdit!.dueDate = _dueDate;
        widget.taskToEdit!.priority = _priority;
        widget.taskToEdit!.taskListId = _selectedTaskListId;
        await taskProvider.updateTask(widget.taskToEdit!);
        success = true;
      } catch (e) {
        print("Error updating task: $e");
      }
    } else {
      final newTask = Task(
          title: _titleController.text,
          description: _descriptionController.text,
          isCompleted: _isCompleted,
          isStarred: _isStarred,
          dueDate: _dueDate,
          priority: _priority,
          taskListId: _selectedTaskListId);
      success = await taskProvider.addTask(newTask);
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save task. Please try again."), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Use only lists that can hold tasks for the dropdown
          final assignableLists = taskProvider.assignableTaskLists;

          if (!assignableLists.any((list) => list.id == _selectedTaskListId) && assignableLists.isNotEmpty) {
            _selectedTaskListId = assignableLists.first.id;
          }
          bool canSave = assignableLists.isNotEmpty;

          return Scaffold(
            appBar: AppBar(title: Text(widget.taskToEdit == null ? 'Add Task' : 'Edit Task'), actions: [
              IconButton(icon: const Icon(Icons.save), onPressed: canSave ? _saveTask : null)
            ]),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => v!.isEmpty ? 'Title cannot be empty' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description (Optional)'), maxLines: 3),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_dueDate == null ? 'Set Due Date' : 'Due: ${DateFormat.yMd().add_jm().format(_dueDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDueDate,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Priority>(
                        value: _priority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.toString().split('.').last.capitalize()))).toList(),
                        onChanged: (v) { if (mounted) setState(() => _priority = v!); }),
                    const SizedBox(height: 16),
                    if (assignableLists.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: assignableLists.any((list) => list.id == _selectedTaskListId) ? _selectedTaskListId : null,
                        decoration: const InputDecoration(labelText: 'Assign to List'), // Changed label
                        items: assignableLists.map((list) => DropdownMenuItem(value: list.id, child: Text(list.name))).toList(),
                        onChanged: (v) { if (mounted) setState(() => _selectedTaskListId = v!);},
                        validator: (v) => v == null ? 'Please select a list' : null,
                      )
                    else
                      const Padding(padding: EdgeInsets.symmetric(vertical:8.0), child: Text("No lists available to add tasks. Create a list first.", style: TextStyle(color: Colors.orangeAccent))),
                    const SizedBox(height: 16),
                    SwitchListTile(title: const Text('Mark as Starred'), value: _isStarred, onChanged: (v) { if (mounted) setState(() => _isStarred = v);}, secondary: Icon(_isStarred ? Icons.star_rounded : Icons.star_border_rounded, color: _isStarred ? Theme.of(context).colorScheme.primary : null)),
                    if (widget.taskToEdit != null) SwitchListTile(title: const Text('Completed'), value: _isCompleted, onChanged: (v) { if (mounted) setState(() => _isCompleted = v);}),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: canSave ? _saveTask : null, child: Text(widget.taskToEdit == null ? 'Add Task' : 'Save Changes')),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}

// Screen for displaying tasks within a specific list (isCategoryOnly = false)
class TaskListScreen extends StatelessWidget {
  final String taskListId;
  final List<Task> tasksToDisplay;

  const TaskListScreen({
    super.key,
    required this.taskListId,
    required this.tasksToDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final taskList = taskProvider.getTaskListById(taskListId);

    if (taskList == null || taskList.isCategoryOnly) { // Should not happen if routing is correct
      return const Center(child: Text("Error: Invalid list for tasks."));
    }

    return FilteredTasksView(
      key: ValueKey("TaskListScreenContent_$taskListId${tasksToDisplay.length}"),
      viewTitle: taskList.name,
      tasks: tasksToDisplay,
      headerIcon: Icons.list_alt_outlined,
      emptyMessage: 'No tasks in "${taskList.name}" yet.',
      associatedListIdForAdd: taskListId, // Allows adding tasks to this list
      currentSearchQuery: "",
    );
  }
}

// Screen for displaying sub-lists within a category (isCategoryOnly = true)
class CategoryContentView extends StatelessWidget {
  final TaskList category;
  final Function(AppViewType, String?, String) setViewCallback;
  final Function(BuildContext, TaskProvider, [TaskList?, String?, bool?]) showAddEditDialogCallback;


  const CategoryContentView({
    super.key,
    required this.category,
    required this.setViewCallback,
    required this.showAddEditDialogCallback,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    // Get both sub-categories and sub-lists for this category
    final subItems = taskProvider.getAllSubItems(category.id);
    // Separate them for potentially different rendering or sorting
    final subCategories = subItems.where((item) => item.isCategoryOnly).toList();
    final subLists = subItems.where((item) => !item.isCategoryOnly).toList();


    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: Text('Add New List to "${category.name}"'),
            onPressed: () {
              // Adding a list (not a category) under this category
              showAddEditDialogCallback(context, taskProvider, null, category.id, false);
            },
          ),
        ),
        if (subItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No lists or sub-categories in "${category.name}" yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Display Sub-Categories first (optional, could interleave or sort by name/date)
        if (subCategories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
            child: Text("SUB-CATEGORIES", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          ...subCategories.map((subCat) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.folder_special_outlined, color: Theme.of(context).colorScheme.secondary),
                title: Text(subCat.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setViewCallback(AppViewType.category, subCat.id, subCat.name),
              ),
            );
          }),
          if (subLists.isNotEmpty) const Divider(height: 20, thickness: 1),
        ],

        // Display Sub-Lists
        if (subLists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
            child: Text("LISTS", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          ...subLists.map((subList) {
            int taskCount = taskProvider.getTasksForList(subList.id).where((t) => !t.isCompleted).length;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.list_alt_rounded, color: Theme.of(context).colorScheme.secondary),
                title: Text(subList.name),
                trailing: taskCount > 0
                    ? Chip(label: Text(taskCount.toString()), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)
                    : const Icon(Icons.chevron_right),
                onTap: () => setViewCallback(AppViewType.taskList, subList.id, subList.name),
              ),
            );
          })
        ],
      ],
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppViewType _currentViewType = AppViewType.allTasks;
  String? _selectedListId; // Can be ID of a TaskList or a Category
  String _currentAppBarTitle = "All Tasks";

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) _updateSearchQuery(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (taskProvider.taskLists.isNotEmpty) {
        final firstItem = taskProvider.taskLists.first;
        _setView(firstItem.isCategoryOnly ? AppViewType.category : AppViewType.taskList, firstItem.id, firstItem.name);
      } else {
        _setView(AppViewType.allTasks, null, "All Tasks");
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setView(AppViewType viewType, String? listId, String appBarTitle) {
    if (!mounted) return;
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
    if (_isSearching && (_currentViewType != viewType || _selectedListId != listId)) {
      _stopSearch();
    }
    setState(() {
      _currentViewType = viewType;
      _selectedListId = listId;
      _currentAppBarTitle = appBarTitle;
    });
  }

  void _startSearch() {
    if (!mounted) return;
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    if (!mounted) return;
    _searchController.clear();
    setState(() => _isSearching = false);
  }

  void _updateSearchQuery(String query) {
    if (!mounted) return;
    setState(() => _searchQuery = query.toLowerCase());
  }

  List<Task> _filterTasks(List<Task> tasks) {
    if (_searchQuery.isEmpty) return tasks;
    return tasks.where((task) =>
    task.title.toLowerCase().contains(_searchQuery) ||
        (task.description?.toLowerCase().contains(_searchQuery) ?? false))
        .toList();
  }


  void _navigateAndDisplayAddTaskScreen(BuildContext navContext, String taskListIdForTask) {
    if (!mounted) return;
    // Ensure taskListIdForTask is for a list, not a category
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final list = taskProvider.getTaskListById(taskListIdForTask);
    if (list != null && !list.isCategoryOnly) {
      Navigator.of(navContext).push(MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(taskListId: taskListIdForTask),
      ));
    } else {
      ScaffoldMessenger.of(navContext).showSnackBar(
          const SnackBar(content: Text("Cannot add task here. Select a specific list.")));
    }
  }

  void _showAddOrEditTaskListDialog(
      BuildContext dialogHostContext,
      TaskProvider taskProvider,
      [TaskList? listToEdit, String? initialParentId, bool? forceIsCategoryOnly]
      // forceIsCategoryOnly: null = user decides, true = must be category, false = must be list
      ) {
    if (!mounted) return;
    final nameController = TextEditingController(text: listToEdit?.name ?? '');
    String? selectedParentId = listToEdit?.parentId ?? initialParentId;
    // Initial state of the "isCategoryOnly" switch
    bool isCategoryOnlySwitch = forceIsCategoryOnly ?? listToEdit?.isCategoryOnly ?? false;
    // If editing, the type (category/list) should not change
    final bool isEditing = listToEdit != null;


    // Potential parents are always categories or null (for top-level)
    List<TaskList> potentialParentItems = [
      TaskList(id: '', name: 'None (Top Level)', isCategoryOnly: true), // Placeholder for null
      ...taskProvider.potentialParentCategories,
    ];
    // Filter out the current list being edited if it's a category itself
    if (isEditing && listToEdit.isCategoryOnly) {
      potentialParentItems.removeWhere((item) => item.id == listToEdit.id);
    }


    showDialog(
        context: dialogHostContext,
        builder: (alertDialogContext) {
          // Use StatefulBuilder to manage the state of the switch inside the dialog
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text(isEditing ? 'Edit ${listToEdit.isCategoryOnly ? "Category" : "List"}' : 'Add New'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: nameController, autofocus: true, decoration: InputDecoration(hintText: isCategoryOnlySwitch ? 'Category name' : 'List name')),
                        const SizedBox(height: 16),
                        if (!isEditing && forceIsCategoryOnly == null) // Only show switch if creating new AND type is not forced
                          SwitchListTile(
                            title: const Text('Main Category (no tasks)'),
                            value: isCategoryOnlySwitch,
                            onChanged: (val) {
                              setDialogState(() {
                                isCategoryOnlySwitch = val;
                              });
                            },
                          ),
                        // Dropdown for parent selection
                        DropdownButtonFormField<String?>(
                          value: selectedParentId,
                          decoration: const InputDecoration(labelText: 'Parent Category (Optional)'),
                          items: taskProvider.potentialParentCategories.map((TaskList parentCat) {
                            return DropdownMenuItem<String?>(
                              value: parentCat.id,
                              child: Text(parentCat.name),
                            );
                          }).toList()
                            ..insert(0, const DropdownMenuItem<String?>(value: null, child: Text('None (Top Level)'))), // Add "None" option
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              selectedParentId = newValue;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(alertDialogContext).pop(), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(dialogHostContext).showSnackBar(const SnackBar(content: Text("Name cannot be empty.")));
                          return;
                        }
                        Navigator.of(alertDialogContext).pop();

                        if (!isEditing) { // ADDING NEW
                          final actualIsCategoryOnly = forceIsCategoryOnly ?? isCategoryOnlySwitch;
                          final newItem = TaskList(name: name, parentId: selectedParentId, isCategoryOnly: actualIsCategoryOnly);
                          await taskProvider.addTaskList(newItem);

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _setView(actualIsCategoryOnly ? AppViewType.category : AppViewType.taskList, newItem.id, newItem.name);
                          });
                        } else { // EDITING EXISTING
                          await taskProvider.updateTaskList(listToEdit, newName: name, newParentId: selectedParentId);
                          // isCategoryOnly is not changed during edit
                          if (_selectedListId == listToEdit.id) { // If the edited item was the one being viewed
                            if (mounted) _setView(listToEdit.isCategoryOnly ? AppViewType.category : AppViewType.taskList, listToEdit.id, listToEdit.name);
                          }
                        }
                      },
                      child: Text(isEditing ? 'Save' : 'Add'),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  void _showDeleteListConfirmationDialog(BuildContext dialogHostContext, TaskProvider taskProvider, TaskList list) {
    if (!mounted) return;
    showDialog(
        context: dialogHostContext,
        builder: (alertDialogContext) => AlertDialog(
          title: Text('Delete ${list.isCategoryOnly ? "Category" : "List"}?'),
          content: Text('Are you sure you want to delete "${list.name}" and all its contents (sub-lists, sub-categories, and tasks)? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(alertDialogContext).pop()),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(alertDialogContext).pop();
                String deletedListId = list.id;
                await taskProvider.deleteTaskList(deletedListId);
                if (!mounted) return;
                if (_selectedListId == deletedListId) {
                  if (taskProvider.taskLists.isNotEmpty) {
                    final firstItem = taskProvider.taskLists.first;
                    _setView(firstItem.isCategoryOnly ? AppViewType.category : AppViewType.taskList, firstItem.id, firstItem.name);
                  } else {
                    _setView(AppViewType.allTasks, null, "All Tasks");
                  }
                }
                ScaffoldMessenger.of(dialogHostContext).showSnackBar(
                    SnackBar(content: Text('"${list.name}" deleted.'), duration: const Duration(seconds: 2))
                );
              },
            ),
          ],
        )
    );
  }

  Widget _buildDrawerListTile(TaskList list, BuildContext drawerContext, TaskProvider taskProvider, {bool isSubItem = false, int depth = 0}) {
    final isSelected = (_currentViewType == (list.isCategoryOnly ? AppViewType.category : AppViewType.taskList) && _selectedListId == list.id);
    final subItems = taskProvider.getAllSubItems(list.id); // Get all direct children

    // For categories, task count is irrelevant. For lists, calculate incomplete tasks.
    int taskCount = !list.isCategoryOnly ? taskProvider.getTasksForList(list.id).where((t) => !t.isCompleted).length : 0;

    IconData leadingIcon = list.isCategoryOnly ? Icons.folder_special_outlined : Icons.list_alt_rounded;
    if (isSubItem && !list.isCategoryOnly) leadingIcon = Icons.subdirectory_arrow_right; // Indent sub-lists a bit more visually maybe

    if (subItems.isEmpty && !list.isCategoryOnly) { // Leaf node: a task list with no further sub-items
      return ListTile(
        contentPadding: EdgeInsets.only(left: 16.0 + (depth * 16.0)), // Indentation
        leading: Icon(leadingIcon, color: isSelected ? Theme.of(drawerContext).primaryColor : null, size: 20),
        title: Text(list.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if(taskCount > 0) Chip(label: Text(taskCount.toString()), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, backgroundColor: Theme.of(drawerContext).colorScheme.secondaryContainer.withOpacity(0.7)),
          PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: "Options",
              onSelected: (val) {
                if (val == 'edit') _showAddOrEditTaskListDialog(drawerContext, taskProvider, list);
                if (val == 'delete') _showDeleteListConfirmationDialog(drawerContext, taskProvider, list);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit List'))),
                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete List', style: TextStyle(color: Colors.red)))),
              ])
        ]),
        selected: isSelected,
        selectedTileColor: Theme.of(drawerContext).highlightColor.withOpacity(0.5),
        onTap: () => _setView(AppViewType.taskList, list.id, list.name),
      );
    }

    // Item is a Category, or a List that has sub-items (though lists shouldn't have sub-categories directly under them by design here)
    return ExpansionTile(
      key: PageStorageKey<String>(list.id + depth.toString()),
      tilePadding: EdgeInsets.only(left: 16.0 + (depth * 12.0), right: 8.0), // Indentation for ExpansionTile
      leading: Icon(leadingIcon, color: isSelected ? Theme.of(drawerContext).primaryColor : null, size: 20),
      title: Text(list.name, style: TextStyle(fontWeight: isSelected && _selectedListId == list.id ? FontWeight.bold : FontWeight.normal)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!list.isCategoryOnly && taskCount > 0) // Show task count for lists within categories
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(label: Text(taskCount.toString()), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, backgroundColor: Theme.of(drawerContext).colorScheme.secondaryContainer.withOpacity(0.7)),
          ),
        PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: "Options",
            onSelected: (val) {
              if (val == 'edit') _showAddOrEditTaskListDialog(drawerContext, taskProvider, list);
              if (val == 'delete') _showDeleteListConfirmationDialog(drawerContext, taskProvider, list);
              if (val == 'addListToCategory' && list.isCategoryOnly) {
                _showAddOrEditTaskListDialog(drawerContext, taskProvider, null, list.id, false); // parentId, force isCategoryOnly=false
              }
            },
            itemBuilder: (_) => [
              if (list.isCategoryOnly)
                const PopupMenuItem(value: 'addListToCategory', child: ListTile(leading: Icon(Icons.playlist_add_outlined), title: Text('Add List Here'))),
              PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit ${list.isCategoryOnly ? "Category" : "List"}'))),
              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete ${list.isCategoryOnly ? "Category" : "List"}', style: TextStyle(color: Colors.red)))),
            ]),
        // Expansion icon is provided by ExpansionTile
      ]),
      initiallyExpanded: isSelected || subItems.any((sub) => _selectedListId == sub.id && _currentViewType == (sub.isCategoryOnly ? AppViewType.category : AppViewType.taskList)),
      onExpansionChanged: (isExpanding) {
        if (isExpanding && !isSelected) {
          _setView(list.isCategoryOnly ? AppViewType.category : AppViewType.taskList, list.id, list.name);
        }
      },
      childrenPadding: EdgeInsets.zero, // Children handle their own padding for depth
      children: subItems.map((subItem) => _buildDrawerListTile(subItem, drawerContext, taskProvider, isSubItem: true, depth: depth + 1)).toList(),
    );
  }


  Widget _buildDrawerContent(BuildContext drawerContext, TaskProvider taskProvider, AppSettingsProvider settingsProvider) {
    Widget drawerItem(IconData icon, String title, AppViewType type, {String? listId, int? count}) {
      final isSelected = (_currentViewType == type && (_currentViewType != AppViewType.taskList && _currentViewType != AppViewType.category || _selectedListId == listId));
      return ListTile(
        leading: Icon(icon, color: isSelected ? Theme.of(drawerContext).primaryColor : null),
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        trailing: (count ?? 0) > 0 ? Chip(label: Text(count.toString()), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, backgroundColor: Theme.of(drawerContext).colorScheme.secondaryContainer.withOpacity(0.7)) : null,
        selected: isSelected,
        selectedTileColor: Theme.of(drawerContext).highlightColor.withOpacity(0.5),
        onTap: () => _setView(type, listId, title),
      );
    }

    final topLevelItems = taskProvider.topLevelTaskLists; // This now gets both categories and lists at top level
    int countForView(List<Task> tasks) {
      return _filterTasks(tasks).where((t) => !t.isCompleted).length;
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          accountName: const Text("Personal Organizer"),
          accountEmail: null,
          currentAccountPicture: CircleAvatar(child: Text("PO", style: TextStyle(fontSize: 24, color: Theme.of(drawerContext).colorScheme.onPrimary))),
          decoration: BoxDecoration(color: Theme.of(drawerContext).colorScheme.primary),
        ),
        drawerItem(Icons.all_inbox_outlined, "All Tasks", AppViewType.allTasks, count: countForView(taskProvider.allTasks)),
        drawerItem(Icons.star_outline_rounded, "Starred", AppViewType.starred, count: countForView(taskProvider.starredTasks)),
        drawerItem(Icons.today_outlined, "Today", AppViewType.today, count: countForView(taskProvider.todaysTasks)),
        drawerItem(Icons.calendar_view_week_outlined, "This Week", AppViewType.thisWeek, count: countForView(taskProvider.thisWeeksTasks)),
        const Divider(),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Text("MY CATEGORIES & LISTS", style: Theme.of(drawerContext).textTheme.titleSmall?.copyWith(color: Theme.of(drawerContext).colorScheme.primary, fontWeight: FontWeight.bold))),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Add New Category/List'),
          onTap: () {
            if (MediaQuery.of(drawerContext).size.width < kTabletBreakpoint && _scaffoldKey.currentState?.isDrawerOpen == true) {
              Navigator.of(drawerContext).pop();
            }
            _showAddOrEditTaskListDialog(drawerContext, taskProvider, null, null, null); // null for forceIsCategoryOnly (user decides)
          },
        ),
        if (topLevelItems.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text("No categories or lists yet. Add one!", textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic))),
        ...topLevelItems.map((item) => _buildDrawerListTile(item, drawerContext, taskProvider, depth: 0)),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Deleted Tasks'),
          onTap: () {
            if (MediaQuery.of(drawerContext).size.width < kTabletBreakpoint && _scaffoldKey.currentState?.isDrawerOpen == true) {
              Navigator.of(drawerContext).pop();
            }
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const DeletedTasksScreen(),
            ));
          },
        ),
        ListTile(
            leading: Icon(settingsProvider.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            title: Text(settingsProvider.themeMode == ThemeMode.dark ? "Switch to Light Mode" : "Switch to Dark Mode"),
            onTap: () => settingsProvider.setThemeMode(settingsProvider.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light)),
        // ListTile(
        //   leading: const Icon(Icons.notifications),
        //   title: const Text("Test Notification"),
        //   subtitle: const Text("Send a test notification in 5 seconds"),
        //   onTap: () async {
        //     // Close drawer if open
        //     if (MediaQuery.of(drawerContext).size.width < kTabletBreakpoint && _scaffoldKey.currentState?.isDrawerOpen == true) {
        //       Navigator.of(drawerContext).pop();
        //     }
            
        //     // Show confirmation snackbar
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(
        //         content: Text('Test notification will appear in 5 seconds...'),
        //         duration: Duration(seconds: 2),
        //       ),
        //     );

        //     // Schedule test notification
        //     final now = DateTime.now().add(const Duration(seconds: 5));
        //     final task = Task(
        //       title: "Test Task",
        //       description: "This is a test notification. If you see this, notifications are working!",
        //       priority: Priority.high,
        //       dueDate: now,
        //       taskListId: "test",
        //     );
        //     await NotificationService().scheduleTaskNotification(task);
        //   },
        // ),
        ListTile(leading: const Icon(Icons.info_outline), title: const Text("About"), onTap: () {
          if (MediaQuery.of(drawerContext).size.width < kTabletBreakpoint && _scaffoldKey.currentState?.isDrawerOpen == true) {
            Navigator.of(drawerContext).pop();
          }
          showAboutDialog(context: drawerContext, applicationName: "Personal Organizer", applicationVersion: "1.1.0");
        }),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskProvider, AppSettingsProvider>(
        builder: (context, taskProvider, settingsProvider, child) {
          if (!mounted) return const SizedBox.shrink();

          // Auto-navigation/correction logic
          if ((_currentViewType == AppViewType.taskList || _currentViewType == AppViewType.category)) {
            if (_selectedListId == null || taskProvider.getTaskListById(_selectedListId!) == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (taskProvider.taskLists.isNotEmpty) {
                  final firstItem = taskProvider.taskLists.first;
                  _setView(firstItem.isCategoryOnly ? AppViewType.category : AppViewType.taskList, firstItem.id, firstItem.name);
                } else {
                  _setView(AppViewType.allTasks, null, "All Tasks");
                }
              });
            }
          }


          Widget mainContent;
          List<Task> tasksForCurrentView;
          TaskList? currentSelectedItem = _selectedListId != null ? taskProvider.getTaskListById(_selectedListId!) : null;

          switch (_currentViewType) {
            case AppViewType.category:
              if (currentSelectedItem != null && currentSelectedItem.isCategoryOnly) {
                mainContent = CategoryContentView(
                  key: ValueKey("CategoryView_${currentSelectedItem.id}"),
                  category: currentSelectedItem,
                  setViewCallback: _setView,
                  showAddEditDialogCallback: _showAddOrEditTaskListDialog,
                );
              } else {
                mainContent = const Center(child: Text("Category not found or invalid."));
                // Recovery logic above should kick in
              }
              break;
            case AppViewType.taskList:
              if (currentSelectedItem != null && !currentSelectedItem.isCategoryOnly) {
                tasksForCurrentView = taskProvider.getTasksForList(currentSelectedItem.id);
                mainContent = TaskListScreen(
                  key: ValueKey("TaskListScreen_${currentSelectedItem.id}"),
                  taskListId: currentSelectedItem.id,
                  tasksToDisplay: _filterTasks(tasksForCurrentView),
                );
              } else {
                mainContent = const Center(child: Text("List not found or invalid."));
                // Recovery logic above should kick in
              }
              break;
            case AppViewType.starred:
              tasksForCurrentView = taskProvider.starredTasks;
              mainContent = FilteredTasksView(key: const ValueKey("StarredView"), viewTitle: "Starred", tasks: _filterTasks(tasksForCurrentView), currentSearchQuery: _searchQuery, headerIcon: Icons.star_border_rounded, emptyMessage: "No starred tasks yet.");
              break;
            case AppViewType.today:
              tasksForCurrentView = taskProvider.todaysTasks;
              mainContent = FilteredTasksView(key: const ValueKey("TodayView"), viewTitle: "Today", tasks: _filterTasks(tasksForCurrentView), currentSearchQuery: _searchQuery, headerIcon: Icons.today_outlined, emptyMessage: "No tasks due today.");
              break;
            case AppViewType.thisWeek:
              tasksForCurrentView = taskProvider.thisWeeksTasks;
              mainContent = FilteredTasksView(key: const ValueKey("ThisWeekView"), viewTitle: "This Week", tasks: _filterTasks(tasksForCurrentView), currentSearchQuery: _searchQuery, headerIcon: Icons.calendar_view_week_outlined, emptyMessage: "No tasks due this week.");
              break;
            case AppViewType.allTasks:
            tasksForCurrentView = taskProvider.allTasks;
              if (taskProvider.taskLists.isEmpty && tasksForCurrentView.isEmpty && _searchQuery.isEmpty) {
                mainContent = Center(
                    child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.library_add_check_outlined, size: 80, color: Colors.grey),
                          const SizedBox(height: 20),
                          const Text("Welcome!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text("Create a category (e.g., 'Personal') or a list to get started.", textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text("Create First Item"),
                              onPressed: () {
                                _showAddOrEditTaskListDialog(context, taskProvider, null, null, null);
                              }
                          )
                        ])));
              } else {
                mainContent = FilteredTasksView(key: const ValueKey("AllTasksView"), viewTitle: "All Tasks", tasks: _filterTasks(tasksForCurrentView), currentSearchQuery: _searchQuery, headerIcon: Icons.all_inbox_outlined, emptyMessage: "No tasks yet. Add some!");
              }
              break;
          }

          final bool showFabForTaskAddition =
              _currentViewType == AppViewType.taskList &&
                  currentSelectedItem != null &&
                  !currentSelectedItem.isCategoryOnly &&
                  !_isSearching;


          AppBar appBar(BuildContext appBarContext, {bool isInnerScaffold = false}) {
            final screenWidth = MediaQuery.of(appBarContext).size.width;
            final bool isCurrentDeviceMobile = screenWidth < kTabletBreakpoint;

            return AppBar(
              title: _isSearching
                  ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: 'Search in $_currentAppBarTitle...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(appBarContext).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                    fillColor: Theme.of(appBarContext).colorScheme.surfaceVariant.withOpacity(0.9),
                    filled: true,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(appBarContext).colorScheme.onSurfaceVariant,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(
                    color: Theme.of(appBarContext).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                ),
              )
                  : Text(_currentAppBarTitle),
              automaticallyImplyLeading: isInnerScaffold ? false : isCurrentDeviceMobile,
              actions: [
                if (_isSearching)
                  IconButton(icon: const Icon(Icons.clear), onPressed: _stopSearch, tooltip: "Clear Search")
                else
                  IconButton(icon: const Icon(Icons.search), onPressed: _startSearch, tooltip: "Search Tasks"),
              ],
            );
          }


          return ResponsiveLayoutBuilder(
            mobileBuilder: (mobileContext) => Scaffold(
              key: _scaffoldKey,
              appBar: appBar(mobileContext),
              drawer: Drawer(child: Builder(builder: (drawerContext) => _buildDrawerContent(drawerContext, taskProvider, settingsProvider))),
              body: mainContent,
              floatingActionButton: showFabForTaskAddition
                  ? FloatingActionButton(
                onPressed: () { if (_selectedListId != null) _navigateAndDisplayAddTaskScreen(mobileContext, _selectedListId!);},
                tooltip: 'Add Task to $_currentAppBarTitle',
                child: const Icon(Icons.add),
              )
                  : null,
            ),
            tabletBuilder: (tabletContext) => Scaffold(
              body: Row(children: [
                SizedBox(width: 280, child: Material(elevation: 4, child: Builder(builder: (drawerContentContext) => _buildDrawerContent(drawerContentContext, taskProvider, settingsProvider)))),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: Scaffold(
                  appBar: appBar(tabletContext, isInnerScaffold: true),
                  body: mainContent,
                  floatingActionButton: showFabForTaskAddition
                      ? FloatingActionButton(
                    onPressed: () { if (_selectedListId != null) _navigateAndDisplayAddTaskScreen(tabletContext, _selectedListId!);},
                    tooltip: 'Add Task to $_currentAppBarTitle',
                    child: const Icon(Icons.add),
                  )
                      : null,
                )),
              ]),
            ),
            desktopBuilder: (desktopContext) => Scaffold(
              body: Row(children: [
                SizedBox(width: 320, child: Material(elevation: 4, child: Builder(builder: (drawerContentContext) => _buildDrawerContent(drawerContentContext, taskProvider, settingsProvider)))),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: Scaffold(
                  appBar: appBar(desktopContext, isInnerScaffold: true),
                  body: mainContent,
                  floatingActionButton: showFabForTaskAddition
                      ? FloatingActionButton(
                    onPressed: () {if (_selectedListId != null) _navigateAndDisplayAddTaskScreen(desktopContext, _selectedListId!);},
                    tooltip: 'Add Task to $_currentAppBarTitle',
                    child: const Icon(Icons.add),
                  )
                      : null,
                )),
              ]),
            ),
          );
        }
    );
  }
}


// --- APP ROOT & MAIN ---
class PersonalOrganizerApp extends StatelessWidget {
  const PersonalOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) => MaterialApp(
        title: 'Task Manager',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive and path
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    // Initialize Hive boxes
    await HiveBoxes.init();
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    print('Hive initialized successfully at: ${appDocumentDir.path}');

    // Create and initialize providers using proper async initialization
    final deletedTasksProvider = await DeletedTasksProvider.create();
    final taskProvider = TaskProvider(deletedTasksProvider: deletedTasksProvider);
    
    // Run the app with providers
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
          ChangeNotifierProvider.value(value: taskProvider),
          ChangeNotifierProvider.value(value: deletedTasksProvider),
        ],
        child: const PersonalOrganizerApp(),
      ),
    );
  } catch (e) {
    print('Error initializing app: $e');
    rethrow;
  }
}