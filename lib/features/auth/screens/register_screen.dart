import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final AuthController _controller =
      AuthController();

  bool isLoading = false;

  Future<void> register() async {
    final nameError = Validators.validateName(
      nameController.text.trim(),
    );
    final emailError = Validators.validateEmail(
      emailController.text.trim(),
    );
    final passwordError =
        Validators.validatePassword(
      passwordController.text.trim(),
    );

    if (nameError != null ||
        emailError != null ||
        passwordError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            nameError ??
                emailError ??
                passwordError!,
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = UserModel(
        fullname: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: '',
        createdAt:
            DateTime.now().toString(),
      );

      await _controller.register(user);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Registrasi berhasil',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } on DatabaseException catch (e) {
      final message = e.isUniqueConstraintError()
          ? 'Email sudah terdaftar'
          : 'Registrasi gagal: $e';

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(
              controller:
                  nameController,
              hint: "Nama Lengkap",
            ),

            const SizedBox(height: 16),

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
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: "Daftar",
                    onPressed: register,
                  ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Sudah punya akun? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
