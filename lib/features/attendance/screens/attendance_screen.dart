import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/location_service.dart';
import '../widgets/attendance_button.dart';

class AttendanceScreen
    extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() =>
      _AttendanceScreenState();
}

class _AttendanceScreenState
    extends State<AttendanceScreen> {
  Position? position;
  String? locationError;

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

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Absensi")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              locationError != null
                  ? locationError!
                  : position == null
                      ? "Mengambil lokasi..."
                  : "Lat : ${position!.latitude}\nLng : ${position!.longitude}",
            ),
            const SizedBox(height: 20),

            AttendanceButton(
              text: "Absen Masuk",
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/checkin',
                );
              },
            ),

            const SizedBox(height: 10),

            AttendanceButton(
              text: "Absen Keluar",
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/checkout',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
