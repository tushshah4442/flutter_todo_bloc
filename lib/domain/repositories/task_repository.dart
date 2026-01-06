import '../entities/task.dart';

abstract class TaskRepository {
  /// Fetches all tasks from the data source (Local/Remote)
  /// Throws [AppError] if operations fail
  Future<List<Task>> getTasks();

  /// Adds a new task
  /// Returns the created [Task] with its ID populated
  Future<Task> addTask(String title);

  /// Updates an existing task (e.g. checkbox toggle)
  Future<void> updateTask(Task task);

  /// Deletes a task by ID
  Future<void> deleteTask(String id);
}
