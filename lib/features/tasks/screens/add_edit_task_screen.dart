import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../providers/task_provider.dart';

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
      if (!taskProvider.assignableTaskLists.any((list) => list.id == _selectedTaskListId) &&
          taskProvider.assignableTaskLists.isNotEmpty) {
        setState(() => _selectedTaskListId = taskProvider.assignableTaskLists.first.id);
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
    final initialDate = _dueDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (pickedDate != null) {
      final initialTime = _dueDate != null 
        ? TimeOfDay.fromDateTime(_dueDate!.toLocal()) 
        : TimeOfDay.fromDateTime(DateTime.now().toLocal());
        
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      
      if (pickedTime != null && mounted) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Ensure selected list exists and is not category-only
    final listForTask = taskProvider.getTaskListById(_selectedTaskListId);
    if (listForTask == null) {
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

    bool success = false;
    try {
      if (widget.taskToEdit != null) {
        // Create a new task with the same ID for editing
        final editedTask = Task(
          id: widget.taskToEdit!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          isCompleted: _isCompleted,
          isStarred: _isStarred,
          dueDate: _dueDate,
          priority: _priority,
          taskListId: _selectedTaskListId,
          createdAt: widget.taskToEdit!.createdAt,
        );
        await taskProvider.updateTask(editedTask);
        success = true;
      } else {
        final newTask = Task(
          title: _titleController.text,
          description: _descriptionController.text,
          isCompleted: _isCompleted,
          isStarred: _isStarred,
          dueDate: _dueDate,
          priority: _priority,
          taskListId: _selectedTaskListId,
        );
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving task: $e"), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final assignableLists = taskProvider.assignableTaskLists;

        if (!assignableLists.any((list) => list.id == _selectedTaskListId) && assignableLists.isNotEmpty) {
          _selectedTaskListId = assignableLists.first.id;
        }
        bool canSave = assignableLists.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.taskToEdit == null ? 'Add Task' : 'Edit Task'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save_rounded),
                tooltip: 'Save Task',
                onPressed: canSave ? _saveTask : null,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                              ),
                              validator: (v) => v!.isEmpty ? 'Title cannot be empty' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                alignLabelWithHint: true,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Due Date'),
                            subtitle: _dueDate != null
                              ? Text(
                                  DateFormat('MMM d, y • h:mm a').format(_dueDate!),
                                  style: TextStyle(color: colorScheme.primary),
                                )
                              : Text(
                                  'Not set',
                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                ),
                            leading: Icon(
                              Icons.calendar_today_rounded,
                              color: colorScheme.primary,
                            ),
                            trailing: _dueDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setState(() => _dueDate = null),
                                )
                              : null,
                            onTap: _pickDueDate,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('Priority'),
                            subtitle: Text(
                              _priority.toString().split('.').last.capitalize(),
                              style: TextStyle(
                                color: _getPriorityColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            leading: Icon(
                              _priority == Priority.high
                                ? Icons.priority_high_rounded
                                : _priority == Priority.low
                                  ? Icons.arrow_downward_rounded
                                  : Icons.remove_rounded,
                              color: _getPriorityColor(),
                            ),
                            onTap: () => _showPriorityPicker(),
                          ),
                          if (assignableLists.isNotEmpty) ...[
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('List'),
                              subtitle: Text(
                                assignableLists
                                    .firstWhere((l) => l.id == _selectedTaskListId)
                                    .name,
                                style: TextStyle(color: colorScheme.primary),
                              ),
                              leading: Icon(
                                Icons.list_rounded,
                                color: colorScheme.primary,
                              ),
                              onTap: () => _showListPicker(assignableLists),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Mark as Starred'),
                            value: _isStarred,
                            onChanged: (v) => setState(() => _isStarred = v),
                            secondary: Icon(
                              _isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                              color: _isStarred ? Colors.amber.shade400 : null,
                            ),
                          ),
                          if (widget.taskToEdit != null) ...[
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text('Completed'),
                              value: _isCompleted,
                              onChanged: (v) => setState(() => _isCompleted = v),
                              secondary: Icon(
                                _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                                color: _isCompleted ? colorScheme.primary : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: canSave ? _saveTask : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(widget.taskToEdit == null ? 'Add Task' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor() {
    final theme = Theme.of(context);
    switch (_priority) {
      case Priority.high:
        return theme.brightness == Brightness.dark 
          ? Colors.red.shade300 
          : Colors.red.shade400;
      case Priority.medium:
        return theme.brightness == Brightness.dark 
          ? Colors.orange.shade200 
          : Colors.orange.shade300;
      case Priority.low:
        return theme.brightness == Brightness.dark 
          ? Colors.green.shade200 
          : Colors.green.shade300;
    }
  }

  Future<void> _showPriorityPicker() async {
    final theme = Theme.of(context);
    final result = await showModalBottomSheet<Priority>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Priority.values.map((priority) {
              final isSelected = priority == _priority;
              Color priorityColor;
              IconData priorityIcon;
              
              switch (priority) {
                case Priority.high:
                  priorityColor = theme.brightness == Brightness.dark 
                    ? Colors.red.shade300 
                    : Colors.red.shade400;
                  priorityIcon = Icons.priority_high_rounded;
                  break;
                case Priority.medium:
                  priorityColor = theme.brightness == Brightness.dark 
                    ? Colors.orange.shade200 
                    : Colors.orange.shade300;
                  priorityIcon = Icons.remove_rounded;
                  break;
                case Priority.low:
                  priorityColor = theme.brightness == Brightness.dark 
                    ? Colors.green.shade200 
                    : Colors.green.shade300;
                  priorityIcon = Icons.arrow_downward_rounded;
                  break;
              }

              return ListTile(
                leading: Icon(priorityIcon, color: priorityColor),
                title: Text(
                  priority.toString().split('.').last.capitalize(),
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
                trailing: isSelected 
                  ? Icon(Icons.check, color: theme.colorScheme.primary) 
                  : null,
                onTap: () {
                  Navigator.pop(context, priority);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _priority = result);
    }
  }

  Future<void> _showListPicker(List<TaskList> lists) async {
    final theme = Theme.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: lists.map((list) {
              final isSelected = list.id == _selectedTaskListId;
              return ListTile(
                title: Text(
                  list.name,
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
                trailing: isSelected 
                  ? Icon(Icons.check, color: theme.colorScheme.primary) 
                  : null,
                onTap: () {
                  Navigator.pop(context, list.id);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _selectedTaskListId = result);
    }
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
} 