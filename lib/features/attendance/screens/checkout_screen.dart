import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/attendance_model.dart';
import '../controllers/attendance_controller.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState
    extends State<CheckoutScreen> {
  final AttendanceController _controller =
      AttendanceController();

  AttendanceModel? activeAttendance;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadActiveAttendance();
  }

  Future<void> loadActiveAttendance() async {
    try {
      final userId =
          await StorageService().getUserId();

      if (userId == null) {
        throw Exception(
          'Silakan login ulang terlebih dahulu.',
        );
      }

      final result = await _controller
          .getActiveAttendanceByUser(userId);

      if (!mounted) return;

      setState(() {
        activeAttendance = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> saveCheckOut() async {
    if (isSaving) return;

    if (activeAttendance == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada absen masuk yang aktif.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(DateTime.now());

      await _controller.checkOut(
        activeAttendance!.id!,
        formattedDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Absen keluar berhasil disimpan',
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
            error
                .toString()
                .replaceFirst('Exception: ', ''),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Absen Keluar")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeAttendance == null
                          ? 'Belum ada absen masuk yang aktif.'
                          : 'Absen masuk: ${activeAttendance!.checkIn}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : saveCheckOut,
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
                                "Simpan Absen Keluar",
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
