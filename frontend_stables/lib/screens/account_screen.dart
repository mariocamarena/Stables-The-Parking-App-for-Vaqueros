import 'package:flutter/material.dart';
import '../utils/prefs.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secret.dart';

class AccountScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const AccountScreen({
    Key? key,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _gpsEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Load saved GPS preference
    Prefs.getGpsEnabled().then((value) {
      setState(() {
        _gpsEnabled = value;
        _loading = false;
      });
    });
  }

  Future<void> _onGpsToggle(bool value) async {
    setState(() => _gpsEnabled = value);
    await Prefs.setGpsEnabled(value);

    if (value) {
      try {
        final pos = await determineLatLng();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            'Location: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
          )),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS error: $e')),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Stables: The Parking App for Vaqueros',
      applicationVersion: '1.0',
      applicationIcon: const CircleAvatar(
        backgroundColor: Color(0xFFFF8200),
        child: Icon(
          Icons.local_parking,
          size: 40,
          color: Colors.white,
        ),
      ),
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Stables is a cross-platform app designed to provide real-time parking availability on campus. '
            'It features an interactive map, sensor data simulation, and a reward system for user engagement.',
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Team Members:\n- Mario Camarena\n- Oziel Sauceda\n- Dorcas\n- Victor Silvia\n\nAdvisor:\n- Dr. Andres Figueroa',
        ),
      ],
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change STABLES Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldPasswordController,
                      decoration: const InputDecoration(labelText: 'Old Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your old password';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: newPasswordController,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Confirm New Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                              errorMessage = null;
                            });
                            try {
                              final apiUrl = await Config.getApiUrl();
                              final response = await http.post(
                                Uri.parse('$apiUrl/change-password'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'email': widget.userEmail,
                                  'oldPassword': oldPasswordController.text,
                                  'newPassword': newPasswordController.text,
                                }),
                              );
                              if (response.statusCode == 200) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password changed successfully')),
                                );
                              } else {
                                setState(() {
                                  errorMessage =
                                      jsonDecode(response.body)['error'] ?? 'Change password failed';
                                });
                              }
                            } catch (e) {
                              setState(() => errorMessage = 'Error connecting to server');
                            } finally {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                        child: const Text('Submit'),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFFF8200),
                  child: Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.userEmail,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Account Management Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Account Management', style: Theme.of(context).textTheme.headlineSmall),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () => _showChangePasswordDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const Divider(),
          // Preference Settings Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Preference Settings', style: Theme.of(context).textTheme.headlineSmall),
          ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SwitchListTile(
                  title: const Text('Enable GPS'),
                  value: _gpsEnabled,
                  onChanged: _onGpsToggle,
                ),
          const Divider(),
          // About / App Info Section
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('App Version 1.0', style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
