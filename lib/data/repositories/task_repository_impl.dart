import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../../core/errors/app_error.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

/// Concrete implementation of [TaskRepository].
///
/// This class acts as the single source of truth for data, orchestrating
/// between the [TaskRemoteDataSource] (API) and [TaskLocalDataSource] (Hive).
///
/// It implements the "Offline First" / "Smart Sync" strategy.
class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final InternetConnection connectionChecker;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectionChecker,
  });

  /// Fetches tasks based on connectivity.
  ///
  /// - **Online**: Fetches from API, merges with local-only tasks, caches result.
  /// - **Offline**: Returns cached tasks.
  @override
  Future<List<Task>> getTasks() async {
    // 1. Check Internet
    bool hasConnection = await connectionChecker.hasInternetAccess;

    if (hasConnection) {
      try {
        // Online: Fetch Remote
        final remoteTasks = await remoteDataSource.getTasks();

        // SMART MERGE:
        // Fetch existing local tasks to preserve ones that are "local-only"
        // (Tasks created while offline have timestamp-based IDs, while server uses 1-200)
        final localTasksRaw = await localDataSource.getLastTasks();

        final localAddedTasks = localTasksRaw.where((t) {
          // Keep task if it is NOT present in the remote list (i.e. it's new/local)
          return !remoteTasks.any((remote) => remote.id == t.id);
        }).toList();

        // Merge: Local New Tasks + Remote Tasks
        final mergedTasks = [...localAddedTasks, ...remoteTasks];

        // Save merged list to Local Cache
        await localDataSource.cacheTasks(mergedTasks);

        // Return Merged List
        return mergedTasks.map((m) => m.toEntity()).toList();
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

  /// Helper to get local tasks with specific sort order.
  Future<List<Task>> _getLocalTasks() async {
    try {
      final localTasks = await localDataSource.getLastTasks();
      // Reverse the list to show newest first (assuming insertion order)
      return localTasks.reversed.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw CacheError();
    }
  }

  /// Adds a task to both Local and Remote sources.
  /// - If Offline: Generates temp ID and saves locally.
  /// - If Online: Posts to server (for mock response) AND saves locally.
  @override
  Future<Task> addTask(String title) async {
    bool hasConnection = await connectionChecker.hasInternetAccess;

    // Generate a unique ID (Timestamp) for uniqueness
    // JSONPlaceholder always returns ID 201, which breaks list uniqueness if multiple tasks are added.
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

    if (hasConnection) {
      try {
        await remoteDataSource.addTask(title);
        // We ignore the returned model's ID (which is 201) and use our uniqueId

        final localModel = TaskModel(
          id: uniqueId,
          title: title,
          isCompleted: false,
        );

        // Persist local
        await localDataSource.addTask(localModel);
        return localModel.toEntity();
      } catch (e) {
        throw ServerError();
      }
    } else {
      // Offline Creation
      final localModel = TaskModel(
        id: uniqueId,
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

    // Optimistic Update: Always update local DB immediately
    await localDataSource.updateTask(model);

    bool hasConnection = await connectionChecker.hasInternetAccess;
    if (hasConnection) {
      try {
        await remoteDataSource.updateTask(model);
      } catch (e) {
        // In a real app, queue this for retry.
        // For this assignment, we accept the optimistic local update.
      }
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    // Optimistic Delete: Remove from local DB immediately
    await localDataSource.deleteTask(id);

    bool hasConnection = await connectionChecker.hasInternetAccess;
    if (hasConnection) {
      try {
        await remoteDataSource.deleteTask(id);
      } catch (e) {
        // Silent fail (cache is already updated)
      }
    }
  }
}
