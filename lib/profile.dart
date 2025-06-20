// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/api_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}


class _ProfileState extends State<Profile> {
  final user = FirebaseAuth.instance.currentUser!;
  final ApiService _apiService = ApiService();

  List<Todo> _todos = [];

  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadTodos();
  }
  
  void _loadTodos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final todos = await _apiService.fetchTodos();
      setState(() {
        _todos = todos;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading todos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
  


  void _showAddEditTodoDialog({Todo? todo}) {
    final bool isEditing = todo != null;
    final TextEditingController nameController = TextEditingController(text: isEditing ? todo.name : '');
    final TextEditingController descriptionController = TextEditingController(text: isEditing ? todo.description : '');
    bool isCompleted = isEditing ? todo.completed : false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Todo' : 'Add Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Todo Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              CheckboxListTile(
                title: Text('Completed'),
                value: isCompleted,
                onChanged: (value) {
                  setState(() {
                    isCompleted = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final newTodo = Todo(
                  id: isEditing ? todo.id : null,
                  name: nameController.text,
                  description: descriptionController.text,
                  completed: isCompleted,
                );
                
                try {
                  if (isEditing) {
                    await _apiService.updateTodo(todo.id!, newTodo);
                  } else {
                    await _apiService.createTodo(newTodo);
                  }
                  _loadTodos();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          // User info section
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.person, size: 30) : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'No Name',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 4),
                      Text(
                        user.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          // Todo list section
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _todos.isEmpty
                    ? Center(child: Text('No todos yet. Add one!'))
                    : ListView.builder(
                        itemCount: _todos.length,
                        itemBuilder: (context, index) {
                          final todo = _todos[index];
                          return Dismissible(
                            key: Key(todo.id!),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,

                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Confirm'),
                                  content: Text('Are you sure you want to delete this todo?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              try {
                                await _apiService.deleteTodo(todo.id!);
                                setState(() {
                                  _todos.removeAt(index);
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error deleting todo: $e')),
                                );
                                _loadTodos(); // Reload to restore the list
                              }
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text(
                                  todo.name,
                                  style: TextStyle(
                                    decoration: todo.completed ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                subtitle: Text(todo.description),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: todo.completed,
                                      onChanged: (bool? value) async {
                                        try {
                                          await _apiService.updateTodo(
                                            todo.id!,
                                            Todo(
                                              name: todo.name,
                                              description: todo.description,
                                              completed: value ?? false,
                                            ),
                                          );
                                          _loadTodos();
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error updating todo: $e')),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () => _showAddEditTodoDialog(todo: todo),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTodoDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
