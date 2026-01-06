import 'package:hive/hive.dart';
import '../../core/errors/app_error.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getLastTasks();
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box box;
  static const String boxName = 'tasks_box';

  TaskLocalDataSourceImpl({required this.box});

  @override
  Future<List<TaskModel>> getLastTasks() async {
    // Hive stores data as a generic Map, but because we haven't run the generator yet
    // we will store them as simple JSON strings or Maps for now to avoid complexity?
    // User requested "Hive -> Tasks offline storage".
    // Best practice with TypeAdapters:
    try {
      final List<dynamic> rawList = box.values.toList();
      // Safely cast or map
      return rawList.cast<TaskModel>();
    } catch (e) {
      throw CacheError();
    }
  }

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    await box.clear();
    // Putting tasks in box. Use ID as key for ensuring updates work easy
    for (var task in tasks) {
      await box.put(task.id, task);
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    await box.put(task.id, task);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await box.put(task.id, task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await box.delete(id);
  }
}
