import 'package:flutter/material.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/user_model.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen
    extends StatefulWidget {
  const EditProfileScreen(
      {super.key});

  @override
  State<EditProfileScreen>
      createState() =>
          _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final ProfileController _controller =
      ProfileController();

  final nameController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  UserModel? user;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final userId =
        await StorageService().getUserId();

    if (userId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan login ulang terlebih dahulu.',
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }

    user = await _controller
        .getUserById(userId);

    if (user != null) {
      nameController.text =
          user!.fullname;

      phoneController.text =
          user!.phone ?? '';
    }

    if (!mounted) return;

    setState(() {});
  }

  Future<void> updateProfile() async {
    if (isSaving) return;

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Nama lengkap wajib diisi',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    final updatedUser = UserModel(
      id: user!.id,
      fullname:
          nameController.text.trim(),
      email: user!.email,
      password: user!.password,
      phone:
          phoneController.text.trim(),
      createdAt: user!.createdAt,
    );

    try {
      await _controller.updateProfile(
        updatedUser,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Profil berhasil diperbarui",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui profil: $error',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Edit Profil"),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller:
                  nameController,
              decoration:
                  const InputDecoration(
                labelText:
                    "Nama Lengkap",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  phoneController,
              decoration:
                  const InputDecoration(
                labelText:
                    "Nomor HP",
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : updateProfile,
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Simpan",
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
