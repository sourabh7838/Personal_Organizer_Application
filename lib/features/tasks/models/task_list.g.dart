// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskListAdapter extends TypeAdapter<TaskList> {
  @override
  final int typeId = 2;

  @override
  TaskList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskList(
      id: fields[0] as String?,
      name: fields[1] as String,
      iconName: fields[2] as String?,
      createdAt: fields[3] as DateTime?,
      parentId: fields[4] as String?,
      isCategoryOnly: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TaskList obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconName)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.parentId)
      ..writeByte(5)
      ..write(obj.isCategoryOnly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
