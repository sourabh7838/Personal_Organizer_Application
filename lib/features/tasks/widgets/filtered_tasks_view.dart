import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_tile.dart';

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
      _incompleteTasks = List.from(widget.tasks.where((task) => !task.isCompleted));
      _completedTasks = List.from(widget.tasks.where((task) => task.isCompleted));
    });
  }

  void _handleTaskDeleted(String taskId) {
    setState(() {
      _incompleteTasks.removeWhere((t) => t.id == taskId);
      _completedTasks.removeWhere((t) => t.id == taskId);
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
            (task) => TaskTile(
              key: ValueKey("task_${task.id}"),
              task: task,
              onDeleted: () => _handleTaskDeleted(task.id),
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
            (task) => TaskTile(
              key: ValueKey("task_${task.id}"),
              task: task,
              onDeleted: () => _handleTaskDeleted(task.id),
            ),
          ),
      ],
    );
  }
} 