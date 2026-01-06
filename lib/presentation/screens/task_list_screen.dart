import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state_event.dart';
import '../../blocs/task/task_bloc.dart';
import '../../blocs/task/task_state_event.dart';
import '../../main.dart';
import '../../core/theme/app_dimensions.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_item.dart';
import 'login_screen.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );

    if (title != null && context.mounted) {
      context.read<TaskBloc>().add(AddTask(title: title));
      // Clear search if adding new task to see it
      if (_isSearching) {
        setState(() {
          _isSearching = false;
          _searchController.clear();
        });
        context.read<TaskBloc>().add(const SearchTasks(''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).appBarTheme.titleTextStyle?.color?.withOpacity(0.5),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                  fontSize: 20,
                ),
                onChanged: (val) {
                  context.read<TaskBloc>().add(SearchTasks(val));
                },
              )
            : const Text('My Tasks'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  context.read<TaskBloc>().add(const SearchTasks(''));
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle Theme',
            onPressed: () {
              // To access MyAppState which is in main.dart, we need to import main.dart
              // However, circular dependency might occur if main imports task_list.
              // Main imports task_list. Task_list imports main?
              // Yes, circular dependency risk.
              // Better solution: Pass a callback or use a ValueNotifier?
              // Or just use 'dynamic' lookup for this simple hack or cleaner:
              // context.findAncestorStateOfType<MyAppState>() requires MyAppState visible.
              MyApp.of(context)?.toggleTheme();
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          bool hasInternet = await InternetConnection().hasInternetAccess;
          if (hasInternet) {
            if (context.mounted) context.read<TaskBloc>().add(LoadTasks());
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You are offline. Cannot refresh."),
                ),
              );
            }
          }
        },
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TaskError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.p24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            } else if (state is TaskLoaded) {
              final tasksToShow = state.filteredTasks ?? state.tasks;

              if (tasksToShow.isEmpty && state.tasks.isEmpty) {
                // Really empty (no tasks at all)
                return _buildEmptyState(context, "No tasks yet");
              } else if (tasksToShow.isEmpty && state.tasks.isNotEmpty) {
                // Empty because of search
                return _buildEmptyState(context, "No tasks found");
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.p8),
                itemCount: tasksToShow.length,
                itemBuilder: (context, index) {
                  final task = tasksToShow[index];
                  return TaskItem(
                    task: task,
                    onCheckboxChanged: (val) {
                      context.read<TaskBloc>().add(
                        UpdateTask(task: task.copyWith(isCompleted: val)),
                      );
                    },
                    onDelete: () {
                      context.read<TaskBloc>().add(DeleteTask(id: task.id));
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      // ListView needs a child to allow Pull-to-Refresh even when empty
      child: ListView(
        shrinkWrap: true,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt,
                size: AppDimensions.iconXLarge,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: AppDimensions.p16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
