// ignore_for_file: non_constant_identifier_names, library_prefixes, avoid_print, duplicate_ignore

import 'dart:convert';
import 'dart:math' as Math;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class Todo {
  final String? id;
  final String name;
  final String description;
  final bool completed;
  final String? user_id;  // Added user_id field, nullable

  Todo({
    this.id,
    required this.name,
    required this.description,
    required this.completed,
    this.user_id,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      completed: json['completed'],
      user_id: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    // Only include user_id if it exists
    Map<String, dynamic> json = {
      'name': name,
      'description': description,
      'completed': completed,
    };
    if (user_id != null) json['user_id'] = user_id;
    return json;
  }
}



class ApiService {
  final String baseUrl = 'https://fastapi-app-production-6e30.up.railway.app';
  
  Future<String?> _getAuthToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    // Add await here and force refresh the token
    return await user.getIdToken(true);
  }

  

  Future<List<Todo>> fetchTodos() async {
    final token = await _getAuthToken();

    final response = await http.get(
      Uri.parse('$baseUrl/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Add some debug logging to help troubleshoot
    // ignore: avoid_print
    print("Fetch todos response: ${response.statusCode} - ${response.body.substring(0, Math.min(100, response.body.length))}");

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Todo.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load todos. Status code: ${response.statusCode}');
    }
  }




  Future<void> createTodo(Todo todo) async {
    try {
      final token = await _getAuthToken();
      final todoJson = todo.toJson();
      print("Sending todo: $todoJson"); // Debug what we're sending
      
      final response = await http.post(
        Uri.parse('$baseUrl/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(todoJson),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create todo. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print("Error creating todo: $e");
      rethrow;
    }
  }

  Future<void> updateTodo(String id, Todo todo) async {
    final token = await _getAuthToken();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(todo.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update todo. Status code: ${response.statusCode}');
    }
  }

  Future<void> deleteTodo(String id) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete todo. Status code: ${response.statusCode}');
    }
  }
}