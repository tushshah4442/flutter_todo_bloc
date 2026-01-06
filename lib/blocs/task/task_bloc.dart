import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_state_event.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;

  TaskBloc({required this.taskRepository}) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<SearchTasks>(_onSearchTasks);
  }

  void _onSearchTasks(SearchTasks event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(TaskLoaded(currentState.tasks, filteredTasks: null));
      } else {
        final filtered = currentState.tasks.where((t) {
          return t.title.toLowerCase().contains(query);
        }).toList();

        emit(TaskLoaded(currentState.tasks, filteredTasks: filtered));
      }
    }
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final tasks = await taskRepository.getTasks();
      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoaded) {
      try {
        // Optimistic Update: We could insert a temp task, but for Add,
        // it's safer to wait for ID from Repo (server/local)
        final newTask = await taskRepository.addTask(event.title);

        // Prepend result to current list (Newest first)
        final currentTasks = (state as TaskLoaded).tasks;
        emit(TaskLoaded([newTask, ...currentTasks]));
      } catch (e) {
        emit(TaskError("Failed to add task: $e"));
        // Re-emit old list? In simple app, showing error is enough.
      }
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoaded) {
      final currentTasks = (state as TaskLoaded).tasks;

      // Optimistic Update:
      // 1. Immediately update UI
      final updatedTasks = currentTasks.map((t) {
        return t.id == event.task.id ? event.task : t;
      }).toList();
      emit(TaskLoaded(updatedTasks));

      // 2. Call API in background
      try {
        await taskRepository.updateTask(event.task);
      } catch (e) {
        // 3. Rollback if fail
        emit(TaskError("Failed to update task: $e"));
        emit(TaskLoaded(currentTasks)); // Revert
      }
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoaded) {
      final currentTasks = (state as TaskLoaded).tasks;

      // Optimistic Delete
      final filteredTasks = currentTasks
          .where((t) => t.id != event.id)
          .toList();
      emit(TaskLoaded(filteredTasks));

      try {
        await taskRepository.deleteTask(event.id);
      } catch (e) {
        emit(TaskError("Failed to delete task: $e"));
        emit(TaskLoaded(currentTasks)); // Revert
      }
    }
  }
}
