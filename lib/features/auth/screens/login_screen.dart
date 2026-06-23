import 'package:flutter/material.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final AuthController _controller =
      AuthController();

  bool isLoading = false;

  Future<void> login() async {
    final emailError = Validators.validateEmail(
      emailController.text.trim(),
    );
    final passwordError =
        Validators.validatePassword(
      passwordController.text.trim(),
    );

    if (emailError != null ||
        passwordError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            emailError ?? passwordError!,
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = await _controller.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        await StorageService().saveUserId(
          user.id!,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Email atau Password salah',
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50),

            const Icon(
              Icons.location_on,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              "GeoPresence",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            CustomTextField(
              controller:
                  emailController,
              hint: "Email",
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller:
                  passwordController,
              hint: "Password",
              obscureText: true,
            ),

            const SizedBox(height: 20),

            isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : CustomButton(
                    text: "Login",
                    onPressed: login,
                  ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/register',
                );
              },
              child: const Text(
                "Belum punya akun? Register",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
