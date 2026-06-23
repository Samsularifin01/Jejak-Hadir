import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/attendance_model.dart';
import '../controllers/attendance_controller.dart';
import '../../../core/services/location_service.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() =>
      _CheckinScreenState();
}

class _CheckinScreenState
    extends State<CheckinScreen> {
  final AttendanceController _controller =
      AttendanceController();

  Position? position;
  String? locationError;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    try {
      final currentPosition =
          await LocationService()
              .getCurrentLocation();

      if (!mounted) return;

      setState(() {
        position = currentPosition;
        locationError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        locationError = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> saveCheckIn() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final userId =
          await StorageService().getUserId();

      if (userId == null) {
        throw Exception(
          'Silakan login ulang terlebih dahulu.',
        );
      }

      final activeAttendance =
          await _controller
              .getActiveAttendanceByUser(userId);

      if (activeAttendance != null) {
        throw Exception(
          'Anda sudah absen masuk. Silakan absen keluar terlebih dahulu.',
        );
      }

      var currentPosition = position;
      if (currentPosition == null) {
        currentPosition =
            await LocationService()
                .getCurrentLocation();
      }

      final now = DateTime.now();
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(now);

      await _controller.checkIn(
        AttendanceModel(
          userId: userId,
          checkIn: formattedDate,
          latitude: currentPosition.latitude,
          longitude: currentPosition.longitude,
          address:
              'Lat: ${currentPosition.latitude}, Lng: ${currentPosition.longitude}',
          status: 'Masuk',
          createdAt: formattedDate,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Absen masuk berhasil disimpan',
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
          AppBar(title: const Text("Absen Masuk")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locationError != null
                    ? locationError!
                    : position == null
                        ? "Mengambil lokasi..."
                        : "Lat : ${position!.latitude}\nLng : ${position!.longitude}",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      isSaving ? null : saveCheckIn,
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
                          "Simpan Absen Masuk",
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
