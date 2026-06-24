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
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final AttendanceController _controller = AttendanceController();

  Position? position;
  String? locationError;
  bool isSaving = false;
  bool isLoadingLocation = true;

  static const int _onTimeHour = 7;
  static const int _onTimeMinute = 30;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    setState(() => isLoadingLocation = true);
    try {
      final currentPosition = await LocationService().getCurrentLocation();
      if (!mounted) return;
      setState(() {
        position = currentPosition;
        locationError = null;
        isLoadingLocation = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        locationError = error.toString().replaceFirst('Exception: ', '');
        isLoadingLocation = false;
      });
    }
  }

  String _determineStatus(DateTime checkInTime) {
    final onTimeLimit = DateTime(
      checkInTime.year,
      checkInTime.month,
      checkInTime.day,
      _onTimeHour,
      _onTimeMinute,
    );
    if (checkInTime.isBefore(onTimeLimit) ||
        checkInTime.isAtSameMomentAs(onTimeLimit)) {
      return 'Hadir';
    }
    return 'Terlambat';
  }

  Color _statusColor(String status) =>
      status == 'Hadir' ? Colors.green : Colors.orange;

  IconData _statusIcon(String status) =>
      status == 'Hadir' ? Icons.check_circle_rounded : Icons.warning_rounded;

  Future<void> _showConfirmDialog() async {
    final now = DateTime.now();
    final status = _determineStatus(now);
    final timeStr = DateFormat('HH:mm:ss').format(now);
    final color = _statusColor(status);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded,
                color: Color(0xFF1A56DB)),
            SizedBox(width: 8),
            Text(
              'Konfirmasi Absen Masuk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time_rounded, 'Waktu Masuk', timeStr,
                Colors.blue),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_statusIcon(status), color: color, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Apakah Anda yakin ingin mencatat kehadiran sekarang?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Absen Masuk'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await saveCheckIn();
    }
  }

  Future<void> saveCheckIn() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    try {
      final userId = await StorageService().getUserId();
      if (userId == null) {
        throw Exception('Silakan login ulang terlebih dahulu.');
      }

      final activeAttendance =
          await _controller.getActiveAttendanceByUser(userId);
      if (activeAttendance != null) {
        throw Exception(
            'Anda sudah absen masuk. Silakan absen keluar terlebih dahulu.');
      }

      var currentPosition = position;
      currentPosition ??= await LocationService().getCurrentLocation();

      final now = DateTime.now();
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      final status = _determineStatus(now);

      await _controller.checkIn(
        AttendanceModel(
          userId: userId,
          checkIn: formattedDate,
          latitude: currentPosition.latitude,
          longitude: currentPosition.longitude,
          address:
              'Lat: ${currentPosition.latitude.toStringAsFixed(6)}, Lng: ${currentPosition.longitude.toStringAsFixed(6)}',
          status: status,
          createdAt: formattedDate,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Absen masuk berhasil! Status: $status'),
          backgroundColor:
              status == 'Hadir' ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) setState(() => isSaving = false);
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = _determineStatus(now);
    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Absen Masuk',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF0D3A9E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    DateFormat('HH:mm').format(now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(now),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status),
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Prediksi Status: $status',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Color(0xFF1A56DB), size: 20),
                      const SizedBox(width: 8),
                      const Text('Lokasi Saat Ini',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      if (locationError != null)
                        GestureDetector(
                          onTap: getLocation,
                          child: const Row(
                            children: [
                              Icon(Icons.refresh,
                                  color: Colors.blue, size: 16),
                              SizedBox(width: 4),
                              Text('Coba Lagi',
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (isLoadingLocation)
                    const Row(
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Mendeteksi lokasi...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  else if (locationError != null)
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lat: ${position!.latitude.toStringAsFixed(6)}, Lng: ${position!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(status), color: statusColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status jika absen sekarang: $status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status == 'Hadir'
                              ? 'Tepat waktu sebelum 07:30 WIB'
                              : 'Melewati batas waktu 07:30 WIB',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: (isSaving || locationError != null)
                    ? null
                    : _showConfirmDialog,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.login_rounded),
                label: Text(
                  isSaving ? 'Menyimpan...' : 'Absen Masuk Sekarang',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
