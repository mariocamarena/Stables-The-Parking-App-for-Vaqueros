import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import '../config/secret.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  // Admin login state
  bool _showAdminLogin = false;
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _obscureAdminPassword = true;
  bool _isAdminLoading = false;
  String? _adminErrorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Admin expansion animation
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;

  // Staggered entry animations
  late AnimationController _staggerController;
  late Animation<double> _logoSlide;
  late Animation<double> _titleFade;
  late Animation<double> _formSlide;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();

    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOutCubic,
    );

    // Staggered entry animation
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _logoSlide = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _staggerController.forward();
  }

  void _toggleAdminLogin() {
    setState(() {
      _showAdminLogin = !_showAdminLogin;
      if (_showAdminLogin) {
        _expansionController.forward();
      } else {
        _expansionController.reverse();
        _adminEmailController.clear();
        _adminPasswordController.clear();
        _adminErrorMessage = null;
      }
    });
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

        // Role-based navigation
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

  Future<void> _adminLogin() async {
    final email = _adminEmailController.text.trim();

    setState(() {
      _isAdminLoading = true;
      _adminErrorMessage = null;
    });

    // Domain validation
    if (!email.endsWith('@utrgv.edu')) {
      setState(() {
        _isAdminLoading = false;
        _adminErrorMessage = 'Email must end in @utrgv.edu';
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
          'password': _adminPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'] ?? 'user';

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
          setState(() {
            _adminErrorMessage = 'This account does not have admin privileges';
          });
        }
      } else {
        setState(() {
          _adminErrorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        _adminErrorMessage = 'Error connecting to the server';
      });
    }

    setState(() {
      _isAdminLoading = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _expansionController.dispose();
    _staggerController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const logoUrl = 'https://i.imgur.com/dBNn9fJ.jpg';

    return Scaffold(
      body: Stack(
        children: [
          // Clean 2-stop background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFFAF6F3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  // Clean card styling
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Clean logo with stagger animation
                      AnimatedBuilder(
                        animation: _logoSlide,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _logoSlide.value),
                          child: child,
                        ),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Clean title with fade animation
                      FadeTransition(
                        opacity: _titleFade,
                        child: Column(
                          children: [
                            Text(
                              'STABLES',
                              style: GoogleFonts.fredoka(
                                color: AppColors.utgrvOrange,
                                fontWeight: FontWeight.w600,
                                fontSize: 36,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'The Parking App for Vaqueros',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Form fields with slide animation
                      AnimatedBuilder(
                        animation: _formSlide,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _formSlide.value),
                          child: Opacity(
                            opacity: _titleFade.value,
                            child: child,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'student.01@utrgv.edu',
                              keyboardType: TextInputType.emailAddress,
                              obscureText: false,
                              prefixIcon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 14),

                            // Password field
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'stables123',
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Error message
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _errorMessage != null
                                  ? Padding(
                                      key: const ValueKey('error'),
                                      padding: const EdgeInsets.only(bottom: 14.0),
                                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                    )
                                  : const SizedBox(key: ValueKey('no_error')),
                            ),

                            // Clean login button
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isLoading
                                  ? const CircularProgressIndicator(key: ValueKey('loader'))
                                  : SizedBox(
                                      key: const ValueKey('login_button'),
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.utgrvOrange,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(
                                          'Sign In',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),

                            // Forgot password link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showResetDialog(context),
                                child: Text('Forgot Password?', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                              ),
                            ),

                            // Register link
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                child: Text(
                                  "Don't have an account? Register",
                                  style: GoogleFonts.poppins(color: Colors.blue, fontSize: 13),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Demo notice sticky note
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE6D9A6)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 18, color: Colors.amber[700]),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Demo Mode',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Colors.amber[900],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'The database is no longer active. Using in-memory authentication for this demo. Try the admin dashboard!',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.amber[800],
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Admin button (show when not expanded)
                            if (!_showAdminLogin)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    onPressed: _toggleAdminLogin,
                                    icon: Icon(Icons.admin_panel_settings, size: 18, color: Colors.blueGrey[600]),
                                    label: Text(
                                      'Admin Login',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blueGrey[700],
                                      side: BorderSide(color: Colors.blueGrey[300]!, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Admin expansion section
                            SizeTransition(
                              sizeFactor: _expansionAnimation,
                              child: FadeTransition(
                                opacity: _expansionAnimation,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),

                                    // Clean divider with "Admin Access" label (no icon)
                                    Center(
                                      child: Text(
                                        'Admin Access',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Admin email field
                                    _buildTextField(
                                      controller: _adminEmailController,
                                      label: 'Admin Email',
                                      hint: 'admin@utrgv.edu',
                                      keyboardType: TextInputType.emailAddress,
                                      obscureText: false,
                                      prefixIcon: Icons.person_outline,
                                    ),
                                    const SizedBox(height: 14),

                                    // Admin password field
                                    _buildTextField(
                                      controller: _adminPasswordController,
                                      label: 'Admin Password',
                                      hint: 'admin123',
                                      obscureText: _obscureAdminPassword,
                                      prefixIcon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureAdminPassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () => setState(() => _obscureAdminPassword = !_obscureAdminPassword),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Admin error message
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: _adminErrorMessage != null
                                          ? Padding(
                                              key: const ValueKey('admin_error'),
                                              padding: const EdgeInsets.only(bottom: 14.0),
                                              child: Text(
                                                _adminErrorMessage!,
                                                style: const TextStyle(color: Colors.red),
                                              ),
                                            )
                                          : const SizedBox(key: ValueKey('no_admin_error')),
                                    ),

                                    // Admin login button (subtle grey outline style)
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: _isAdminLoading
                                          ? CircularProgressIndicator(
                                              key: const ValueKey('admin_loader'),
                                              color: Colors.grey[600],
                                            )
                                          : SizedBox(
                                              key: const ValueKey('admin_login_button'),
                                              width: double.infinity,
                                              height: 48,
                                              child: OutlinedButton(
                                                onPressed: _adminLogin,
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.grey[700],
                                                  side: BorderSide(color: Colors.grey[400]!),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Admin Sign In',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Hide admin login button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: OutlinedButton.icon(
                                        onPressed: _toggleAdminLogin,
                                        icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                        label: Text(
                                          'Hide Admin Login',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey[600],
                                          side: BorderSide(color: Colors.grey[400]!),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    IconData? prefixIcon,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Focus(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.utgrvOrange, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.grey[500])
                  : null,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _showResetDialog(BuildContext context) async {
    final emailCtl = TextEditingController();
    final newCtl = TextEditingController();
    final confirmCtl = TextEditingController();
    String? error;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Reset Password',
                  style: GoogleFonts.fredoka(
                    color: AppColors.utgrvOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email and new password',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Email field
                TextField(
                  controller: emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.utgrvOrange, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 14),

                // New password field
                TextField(
                  controller: newCtl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.utgrvOrange, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm password field
                TextField(
                  controller: confirmCtl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.utgrvOrange, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),

                // Error message
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      error!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 20),

                // Buttons row
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Submit button
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () async {
                            final email = emailCtl.text.trim();
                            final npw = newCtl.text;
                            if (npw != confirmCtl.text) {
                              setState(() => error = "Passwords don't match");
                              return;
                            }
                            try {
                              final apiUrl = await Config.getApiUrl();
                              final resp = await http.post(
                                Uri.parse('$apiUrl/change-password'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'email': email,
                                  'newPassword': npw,
                                }),
                              );
                              if (resp.statusCode == 200) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password reset! Please log in.')),
                                );
                              } else {
                                final body = jsonDecode(resp.body);
                                setState(() => error = body['error'] ?? 'Reset failed');
                              }
                            } catch (_) {
                              setState(() => error = 'Network error');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.utgrvOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Submit',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
