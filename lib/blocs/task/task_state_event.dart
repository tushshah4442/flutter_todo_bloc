import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

// --- Events ---
abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final String title;

  const AddTask({required this.title});

  @override
  List<Object?> get props => [title];
}

class UpdateTask extends TaskEvent {
  final Task task;

  const UpdateTask({required this.task});

  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TaskEvent {
  final String id;

  const DeleteTask({required this.id});

  @override
  List<Object?> get props => [id];
}

class SearchTasks extends TaskEvent {
  final String query;

  const SearchTasks(this.query);

  @override
  List<Object?> get props => [query];
}

// --- States ---
abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  final List<Task>? filteredTasks; // Add this

  const TaskLoaded(this.tasks, {this.filteredTasks});

  @override
  List<Object?> get props => [tasks, filteredTasks];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
