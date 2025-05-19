// File: screens/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/secret.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final apiUrl = await Config.getApiUrl();
      final response = await http.get(Uri.parse('$apiUrl/users'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load users';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching users';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(int userId) async {
  final apiUrl = await Config.getApiUrl();
  final response = await http.delete(Uri.parse('$apiUrl/users/$userId'));

  if (response.statusCode == 200) {
    setState(() {
      users.removeWhere((user) => user['id'] == userId);
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete user')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                      child: ListTile(
                        title: Text(user['email'] ?? 'No Email'),
                        subtitle: Text('Role: ${user['role'] ?? 'unknown'} | Zone: ${user['parking_zone'] ?? 'N/A'}'),
                        // subtitle: Text('Role: ${user['role'] ?? 'unknown'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user['id']),
                        ),
                      ),
                    );

                    },
                  ),
      ),
    );
  }
}