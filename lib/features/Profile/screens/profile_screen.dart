import 'package:flutter/material.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/user_model.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final ProfileController _controller =
      ProfileController();

  UserModel? user;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final userId =
        await StorageService().getUserId();

    if (userId != null) {
      user = await _controller
          .getUserById(userId);
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Profil")),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : user == null
              ? const Center(
                  child: Text(
                    "User tidak ditemukan",
                  ),
                )
              : Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        child:
                            Icon(Icons.person),
                      ),

                      const SizedBox(
                          height: 20),

                      ListTile(
                        title:
                            const Text("Nama"),
                        subtitle: Text(
                          user!.fullname,
                        ),
                      ),

                      ListTile(
                        title:
                            const Text("Email"),
                        subtitle: Text(
                          user!.email,
                        ),
                      ),

                      ListTile(
                        title:
                            const Text("No HP"),
                        subtitle: Text(
                          user!.phone ??
                              "-",
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            '/edit-profile',
                          );

                          loadUser();
                        },
                        child: const Text(
                          "Edit Profil",
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
