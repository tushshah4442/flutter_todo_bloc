import 'package:hive/hive.dart';
import '../../domain/entities/task.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final bool isCompleted;

  const TaskModel({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  /// Factory to convert JSON from API to TaskModel
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      // API uses 'id' as int, converting to String for consistency
      id: json['id'].toString(),
      title: json['title'] ?? '',
      isCompleted: json['completed'] ?? false,
    );
  }

  /// Convert TaskModel to JSON for API interactions
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'completed': isCompleted,
      // Note: We generally don't send ID for creation, but might for updates
    };
  }

  /// Convert TaskModel (Dirty) -> Task (Clean Entity)
  Task toEntity() {
    return Task(id: id, title: title, isCompleted: isCompleted);
  }

  /// Create TaskModel (Dirty) <- Task (Clean Entity)
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      isCompleted: task.isCompleted,
    );
  }
}
