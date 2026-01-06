import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../../core/errors/app_error.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final InternetConnection connectionChecker;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectionChecker, // We inject this for testability
  });

  @override
  Future<List<Task>> getTasks() async {
    // 1. Check Internet
    bool hasConnection = await connectionChecker.hasInternetAccess;

    if (hasConnection) {
      try {
        // Online: Fetch Remote
        final remoteTasks = await remoteDataSource.getTasks();
        // Save to Local
        await localDataSource.cacheTasks(remoteTasks);
        // Return Remote (mapped to Entity)
        return remoteTasks.map((m) => m.toEntity()).toList();
      } catch (e) {
        // If Server Fails, Fallback to Cache
        if (e is ServerError) {
          return _getLocalTasks();
        }
        throw ServerError();
      }
    } else {
      // Offline: Return Local
      return _getLocalTasks();
    }
  }

  Future<List<Task>> _getLocalTasks() async {
    try {
      final localTasks = await localDataSource.getLastTasks();
      return localTasks.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw CacheError();
    }
  }

  @override
  Future<Task> addTask(String title) async {
    bool hasConnection = await connectionChecker.hasInternetAccess;

    // We create a temp Model
    // JSONPlaceholder (Mock API) returns ID 201 for every create.
    // In real app, we await server.

    if (hasConnection) {
      try {
        final remoteModel = await remoteDataSource.addTask(title);
        // Persist local
        await localDataSource.addTask(remoteModel);
        return remoteModel.toEntity();
      } catch (e) {
        throw ServerError();
      }
    } else {
      // Offline Creation?
      // User Requirements: "Allow add ... while offline"
      // Strategy: Generate a temporary ID, save local.
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final localModel = TaskModel(
        id: tempId,
        title: title,
        isCompleted: false,
      );
      await localDataSource.addTask(localModel);
      return localModel.toEntity();
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    final model = TaskModel.fromEntity(task);

    // Optimistic Update: Always update local first
    await localDataSource.updateTask(model);

    bool hasConnection = await connectionChecker.hasInternetAccess;
    if (hasConnection) {
      try {
        await remoteDataSource.updateTask(model);
      } catch (e) {
        // If server fails, we have already updated local (Optimistic)
        // In full production app, we would mark this as "dirty/unsynced"
        // For this interview, we silently fail the server sync but keep local change
      }
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    // Optimistic Delete
    await localDataSource.deleteTask(id);

    bool hasConnection = await connectionChecker.hasInternetAccess;
    if (hasConnection) {
      try {
        await remoteDataSource.deleteTask(id);
      } catch (e) {
        // Silent fail
      }
    }
  }
}
