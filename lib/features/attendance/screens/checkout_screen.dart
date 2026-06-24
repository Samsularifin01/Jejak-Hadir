import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/attendance_model.dart';
import '../controllers/attendance_controller.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AttendanceController _controller = AttendanceController();

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
      final userId = await StorageService().getUserId();
      if (userId == null) {
        throw Exception('Silakan login ulang terlebih dahulu.');
      }

      final result =
          await _controller.getActiveAttendanceByUser(userId);

      if (!mounted) return;
      setState(() {
        activeAttendance = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showConfirmDialog() async {
    if (activeAttendance == null) return;

    final now = DateTime.now();
    final checkInTime = DateTime.tryParse(activeAttendance!.checkIn);
    final Duration? duration =
        checkInTime != null ? now.difference(checkInTime) : null;

    final String durationStr = duration != null
        ? '${duration.inHours} jam ${duration.inMinutes.remainder(60)} menit'
        : '-';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text(
              'Konfirmasi Absen Keluar',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _infoRow(
              Icons.login_rounded,
              'Masuk',
              DateFormat('HH:mm').format(
                  DateTime.parse(activeAttendance!.checkIn)),
              Colors.green,
            ),
            const SizedBox(height: 10),
            _infoRow(
              Icons.logout_rounded,
              'Keluar',
              DateFormat('HH:mm').format(now),
              Colors.red,
            ),
            const SizedBox(height: 10),
            _infoRow(
              Icons.timer_rounded,
              'Durasi',
              durationStr,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            const Text(
              'Apakah Anda yakin ingin mencatat kepulangan sekarang?',
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
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Absen Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await saveCheckOut();
    }
  }

  Future<void> saveCheckOut() async {
    if (isSaving || activeAttendance == null) return;
    setState(() => isSaving = true);

    try {
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await _controller.checkOut(activeAttendance!.id!, formattedDate);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absen keluar berhasil disimpan!'),
          backgroundColor: Colors.green,
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

    Duration? duration;
    if (activeAttendance != null) {
      final checkInTime = DateTime.tryParse(activeAttendance!.checkIn);
      if (checkInTime != null) duration = now.difference(checkInTime);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Absen Keluar',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.logout_rounded,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (activeAttendance == null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.orange, size: 40),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada absen masuk aktif',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Silakan lakukan absen masuk terlebih dahulu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Attendance summary card
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
                          const Text(
                            'Rekap Kehadiran Hari Ini',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _infoRow(
                            Icons.login_rounded,
                            'Waktu Masuk',
                            DateFormat('HH:mm').format(
                                DateTime.parse(activeAttendance!.checkIn)),
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.logout_rounded,
                            'Waktu Keluar (rencana)',
                            DateFormat('HH:mm').format(now),
                            Colors.red,
                          ),
                          if (duration != null) ...[
                            const SizedBox(height: 12),
                            _infoRow(
                              Icons.timer_rounded,
                              'Durasi Kehadiran',
                              '${duration.inHours} jam ${duration.inMinutes.remainder(60)} menit',
                              Colors.blue,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.info_rounded,
                            'Status',
                            activeAttendance!.status,
                            activeAttendance!.status == 'Hadir'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                            isSaving ? null : _showConfirmDialog,
                        icon: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.logout_rounded),
                        label: Text(
                          isSaving
                              ? 'Menyimpan...'
                              : 'Absen Keluar Sekarang',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
