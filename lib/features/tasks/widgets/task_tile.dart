import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/add_edit_task_screen.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback? onDeleted;

  const TaskTile({
    super.key,
    required this.task,
    this.onDeleted,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool _isBeingDeleted = false;

  Future<void> _handleDelete() async {
    if (_isBeingDeleted) return;
    
    setState(() => _isBeingDeleted = true);
    
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.deleteTask(widget.task.id);
      
      if (mounted && widget.onDeleted != null) {
        widget.onDeleted!();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBeingDeleted = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  void _handleEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(
          taskToEdit: widget.task,
          taskListId: widget.task.taskListId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isBeingDeleted) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    Color getPriorityColor() {
      switch (widget.task.priority) {
        case Priority.high:
          return Colors.red[400]!;
        case Priority.medium:
          return Colors.orange[300]!;
        case Priority.low:
          return Colors.green[300]!;
      }
    }

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Task?'),
              content: Text('Are you sure you want to delete "${widget.task.title}"?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          await _handleDelete();
          return true;
        }
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text(
            widget.task.title,
            style: TextStyle(
              decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.task.dueDate != null)
                Container(
                  margin: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: widget.task.dueDate!.isBefore(DateTime.now())
                            ? Colors.red[400]
                            : theme.colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(widget.task.dueDate!.toLocal()),
                        style: TextStyle(
                          color: widget.task.dueDate!.isBefore(DateTime.now())
                              ? Colors.red[400]
                              : theme.colorScheme.primary.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.task.description?.isNotEmpty == true)
                Text(
                  widget.task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: getPriorityColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.task.priority == Priority.high
                            ? Icons.priority_high_rounded
                            : widget.task.priority == Priority.low
                              ? Icons.arrow_downward_rounded
                              : Icons.remove_rounded,
                          size: 16,
                          color: getPriorityColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.task.priority.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            color: getPriorityColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          leading: Checkbox(
            value: widget.task.isCompleted,
            onChanged: (bool? value) {
              if (value != null) {
                final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                taskProvider.updateTaskCompletion(widget.task.id, value);
              }
            },
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.task.isStarred)
                Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String value) {
                  switch (value) {
                    case 'edit':
                      _handleEdit();
                      break;
                    case 'delete':
                      _handleDelete();
                      break;
                    case 'toggle_star':
                      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                      taskProvider.toggleTaskStar(widget.task.id);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle_star',
                    child: ListTile(
                      leading: Icon(widget.task.isStarred ? Icons.star_border : Icons.star),
                      title: Text(widget.task.isStarred ? 'Unstar' : 'Star'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 