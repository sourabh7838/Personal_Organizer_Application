import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deleted_tasks_provider.dart';
import '../providers/task_provider.dart';

class DeletedTasksScreen extends StatelessWidget {
  const DeletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Tasks'),
        actions: [
          Consumer<DeletedTasksProvider>(
            builder: (context, provider, _) {
              if (provider.deletedTasks.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Clear All',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Deleted Tasks?'),
                      content: const Text(
                        'This will permanently remove all deleted tasks. This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.clearDeleted();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<DeletedTasksProvider>(
        builder: (context, provider, _) {
          final deletedTasks = provider.deletedTasks;

          if (deletedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No deleted tasks',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: deletedTasks.length,
            itemBuilder: (context, index) {
              final task = deletedTasks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    task.title,
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    'Deleted from ${task.taskListId}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore'),
                    onPressed: () async {
                      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                      final restoredTask = await provider.restoreTask(task.id);
                      if (restoredTask != null) {
                        await taskProvider.addTask(restoredTask);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task restored')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 