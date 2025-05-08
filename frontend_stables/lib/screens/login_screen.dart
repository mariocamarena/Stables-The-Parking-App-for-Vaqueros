import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/secret.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Domain validation
    if (!email.endsWith('@utrgv.edu')) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Email must end in @utrgv.edu';
      });
      return;
    }

    try {
      final apiUrl = await Config.getApiUrl();
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'] ?? 'user';

        // Role‑based navigation
        if (role == 'admin') {
          Navigator.pushReplacementNamed(
            context,
            '/admin',
            arguments: {
              'userId':    data['id'].toString(),
              'userEmail': data['email'],
              'userName':  data['email'].split('@')[0],
            },
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/main',
            arguments: {
              'userId':    data['id'].toString(),
              'userEmail': data['email'],
              'userName':  data['email'].split('@')[0],
            },
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to the server';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFFFF0E0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [



                      Image.network(
                        'https://i.imgur.com/dBNn9fJ.jpg', 
                        width: 80,
                        height: 80,
                      ),





                      const SizedBox(height: 10),
                      Text('STABLES',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              )),
                      const SizedBox(height: 4),
                      Text('The Parking App for Vaqueros',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                                fontSize: 16,
                              )),
                      const SizedBox(height: 40),

                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'student.01@utrgv.edu',
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                      ),
                      const SizedBox(height: 20),

                      // Password field with toggle
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'stables123',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error message
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _errorMessage != null
                            ? Padding(
                                key: const ValueKey('error'),
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                              )
                            : const SizedBox(key: ValueKey('no_error')),
                      ),

                      // Login button or loader
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isLoading
                            ? const CircularProgressIndicator(key: ValueKey('loader'))
                            : ElevatedButton(
                                key: const ValueKey('login_button'),
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.utgrvOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text('Login'),
                              ),
                      ),
                      const SizedBox(height: 16),

                      
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showResetDialog(context),
                              child: const Text('Forgot Password?', style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                      // Register link
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text("Don't have an account? Register",
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Focus(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.utgrvOrange),
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _showResetDialog(BuildContext context) async {
  final emailCtl = TextEditingController();
  final newCtl   = TextEditingController();
  final confirmCtl = TextEditingController();
  String? error;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtl,
              decoration: const InputDecoration(labelText: 'Your email'),
            ),
            TextField(
              controller: newCtl,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
            ),
            TextField(
              controller: confirmCtl,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              obscureText: true,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final email = emailCtl.text.trim();
              final npw   = newCtl.text;
              if (npw != confirmCtl.text) {
                setState(() => error = 'Passwords don’t match');
                return;
              }
              try {
                final apiUrl = await Config.getApiUrl();
                final resp = await http.post(
                  Uri.parse('$apiUrl/change-password'),
                  headers: {'Content-Type':'application/json'},
                  body: jsonEncode({
                    'email': email,
                    'newPassword': npw
                  }),
                );
                if (resp.statusCode == 200) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset! Please log in.'))
                  );
                } else {
                  final body = jsonDecode(resp.body);
                  setState(() => error = body['error'] ?? 'Reset failed');
                }
              } catch (_) {
                setState(() => error = 'Network error');
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    ),
  );
}
}