import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_list.g.dart';

/// Represents a list or category of tasks in the application.
/// 
/// A TaskList can either be a regular list that holds tasks directly,
/// or a category that can contain other lists and categories (when isCategoryOnly = true).
/// This allows for hierarchical organization of tasks.
@HiveType(typeId: 2)
class TaskList extends HiveObject {
  @HiveField(0)
  late String id;

  /// The name of the list or category
  @HiveField(1)
  String name;

  /// Optional icon identifier for visual representation
  @HiveField(2)
  String? iconName;

  /// When this list was created
  @HiveField(3)
  DateTime createdAt;

  /// ID of the parent category (null if this is a top-level item)
  @HiveField(4)
  String? parentId;

  /// Whether this is a category that can only contain other lists/categories
  /// If true, this item cannot contain tasks directly
  @HiveField(5)
  bool isCategoryOnly;

  TaskList({
    String? id,
    required this.name,
    this.iconName,
    DateTime? createdAt,
    this.parentId,
    this.isCategoryOnly = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Whether this item is at the top level of the hierarchy
  bool get isTopLevel => parentId == null;
} 