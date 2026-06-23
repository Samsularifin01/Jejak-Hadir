import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
  final ImagePicker _imagePicker =
      ImagePicker();

  UserModel? user;

  bool isLoading = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    loadUser();
    _loadSavedProfileImage();
  }

  Future<File?> _getProfileImagePath() async {
    try {
      final directory =
          await getApplicationDocumentsDirectory();
      final userId =
          await StorageService().getUserId();
      
      if (userId == null) return null;
      
      final filePath =
          '${directory.path}/profile_images/user_${userId}_profile.png';
      return File(filePath);
    } catch (e) {
      // Log error for debugging
      return null;
    }
  }

  Future<void> _loadSavedProfileImage() async {
    try {
      final profileImage =
          await _getProfileImagePath();
      
      if (profileImage != null &&
          profileImage.existsSync()) {
        setState(() {
          _selectedImage = profileImage;
        });
      }
    } catch (e) {
      // Log error for debugging
    }
  }

  Future<void> _saveProfileImage(
      File imageFile) async {
    try {
      final profileImageFile =
          await _getProfileImagePath();
      
      if (profileImageFile == null) {
        throw Exception('Unable to get profile image path');
      }

      // Create directory if it doesn't exist
      final directory = profileImageFile.parent;
      if (!directory.existsSync()) {
        directory.createSync(
          recursive: true,
        );
      }

      // Copy the selected image to the app documents directory
      await imageFile.copy(
        profileImageFile.path,
      );

      setState(() {
        _selectedImage = profileImageFile;
      });
    } catch (e) {
      // Log error for debugging
      rethrow;
    }
  }

  Future<void> _pickImage(
      ImageSource source) async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final imageFile =
            File(pickedFile.path);
        await _saveProfileImage(imageFile);

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Foto berhasil diubah',
            ),
            duration:
                Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Pilih Sumber Foto',
          ),
          content: const Text(
            'Ambil foto dari mana?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: const Text('Galeri'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: const Text('Kamera'),
            ),
          ],
        );
      },
    );
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
                      GestureDetector(
                        onTap:
                            _showImagePickerDialog,
                        child: Stack(
                          alignment: Alignment
                              .bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  _selectedImage !=
                                          null
                                      ? FileImage(
                                          _selectedImage!,
                                        )
                                      : null,
                              child:
                                  _selectedImage ==
                                          null
                                      ? const Icon(
                                          Icons
                                              .person,
                                        )
                                      : null,
                            ),
                            Container(
                              decoration:
                                  const BoxDecoration(
                                color: Colors
                                    .blue,
                                shape: BoxShape
                                    .circle,
                              ),
                              padding:
                                  const EdgeInsets
                                      .all(4),
                              child: const Icon(
                                Icons
                                    .camera_alt,
                                color: Colors
                                    .white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
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
