import 'signup.dart';
import 'src/auth_services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import './forgotpassword.dart';
import 'main.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Login extends StatefulWidget {
  final ValueNotifier<Locale> localeNotifier;
  const Login({super.key, required this.localeNotifier});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _signUpTapped = false;

  String? emailError;
  String? passwordError;
  String? loginError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 100),

              // ✅ LOGO
              Center(
                child: Image.asset(
                  'assets/psc logo.png',
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 8),
              // 📧 Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email:",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('emailField'),
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "UserEmail@example.com",
                  hintStyle: const TextStyle(color: Colors.white30),
                  errorText: emailError,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: (value) {
                  if (emailError != null && value.isNotEmpty) {
                    setState(() {
                      emailError = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // 🔒 Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('passwordField'),
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: const TextStyle(color: Colors.white30),
                  errorText: passwordError,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
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
                onChanged: (value) {
                  if (passwordError != null && value.isNotEmpty) {
                    setState(() {
                      passwordError = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 30),

              // ✅ SIGN IN Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('loginButton'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 235, 213, 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () async {
                    setState(() {
                      emailError = null;
                      passwordError = null;
                      loginError = null;
                    });

                    if (_emailController.text.isEmpty) {
                      setState(() {
                        emailError = "Please enter your email";
                      });
                      return;
                    }

                    if (_passwordController.text.isEmpty) {
                      setState(() {
                        passwordError = "Please enter your password";
                      });
                      return;
                    }

                    final result = await AuthService().signin(
                      email: _emailController.text,
                      password: _passwordController.text,
                      context: context,
                      localeNotifier: widget.localeNotifier,
                    );

                    if (result != null) {
                      setState(() {
                        if (result.contains("password")) {
                          passwordError = result;
                        } else {
                          emailError = result;
                        }
                      });
                    }
                  },

                  child: const Text(
                    "SIGN IN",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 📎 Sign Up link
              Align(
                alignment: Alignment.centerRight,
                child: Text.rich(
                  TextSpan(
                    text: "Havent sign up? Please click this link to  ",
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                    children: [
                      TextSpan(
                        text: "SIGN UP",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              _signUpTapped
                                  ? const Color.fromARGB(82, 255, 0, 195)
                                  : Colors.yellow,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                setState(() => _signUpTapped = true);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => SignUp(
                                          localeNotifier: widget.localeNotifier,
                                        ),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔁 Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPassword()),
                    );
                  },
                  child: const Text(
                    "FORGOT PASSWORD",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      color: Colors.yellow,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
