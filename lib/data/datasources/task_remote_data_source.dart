import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/errors/app_error.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks();
  Future<TaskModel> addTask(String title);
  Future<TaskModel> updateTask(TaskModel taskModel);
  Future<void> deleteTask(String id);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'https://jsonplaceholder.typicode.com';

  TaskRemoteDataSourceImpl({required this.client});

  @override
  Future<List<TaskModel>> getTasks() async {
    final response = await client.get(
      Uri.parse('$baseUrl/todos?_limit=10'), // Limiting to 10 for demo clarity
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => TaskModel.fromJson(json)).toList();
    } else {
      throw ServerError();
    }
  }

  @override
  Future<TaskModel> addTask(String title) async {
    final response = await client.post(
      Uri.parse('$baseUrl/todos'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title, 'completed': false, 'userId': 1}),
    );

    if (response.statusCode == 201) {
      return TaskModel.fromJson(json.decode(response.body));
    } else {
      throw ServerError();
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel taskModel) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/todos/${taskModel.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(taskModel.toJson()),
    );

    if (response.statusCode == 200) {
      return TaskModel.fromJson(json.decode(response.body));
    } else {
      throw ServerError();
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/todos/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ServerError();
    }
  }
}
