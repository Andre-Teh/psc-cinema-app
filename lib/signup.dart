import 'package:flutter/material.dart';
import './src/auth_services.dart';
import 'login.dart';

class SignUp extends StatefulWidget {
  final ValueNotifier<Locale> localeNotifier;
  const SignUp({super.key, required this.localeNotifier});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeToTnC = false;
  String? _error;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (!_agreeToTnC) {
      setState(() => _error = 'Please accept the Terms and Conditions.');
      return;
    }

    String? result = await _authService.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      context: context,
      localeNotifier: widget.localeNotifier,
      username: _usernameController.text.trim(),
      // Public sign-up always creates a 'customer' account. Staff accounts
      // (admin/manager) are created via the admin dashboard, which sets the
      // role directly, not through this self-service form.
    );

    if (result != null) {
      setState(() => _error = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/psc logo.png',
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel("UserName:"),
              const SizedBox(height: 8),
              _buildTextField(_usernameController, hintText: "UserName1"),

              const SizedBox(height: 20),
              _buildLabel("Email:"),
              const SizedBox(height: 8),
              _buildTextField(
                _emailController,
                hintText: "UserEmail@example.com",
              ),

              const SizedBox(height: 20),
              _buildLabel("Password:"),
              const SizedBox(height: 8),
              _buildTextField(
                _passwordController,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),
              _buildLabel("Confirm Password:"),
              const SizedBox(height: 8),
              _buildTextField(
                _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTnC,
                    onChanged:
                        (value) => setState(() => _agreeToTnC = value ?? false),
                    checkColor: Colors.black,
                    activeColor: Colors.white,
                  ),
                  const Text(
                    'T&C',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 235, 213, 14),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'REGISTER',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => Login(localeNotifier: widget.localeNotifier),
                    ),
                  );
                },
                child: const Text(
                  'ALREADY SIGNED UP? PLEASE CLICK TO SIGN IN',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    String? hintText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white30),
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
