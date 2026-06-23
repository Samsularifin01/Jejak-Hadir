import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/attendance_model.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/menu_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceController _controller =
      AttendanceController();

  String todayStatus = 'Memuat...';

  @override
  void initState() {
    super.initState();
    loadTodayStatus();
  }

  Future<void> loadTodayStatus() async {
    final userId =
        await StorageService().getUserId();

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        todayStatus = 'Belum Login';
      });
      return;
    }

    final histories = await _controller
        .getAttendanceByUser(userId);
    final todayPrefix =
        DateFormat('yyyy-MM-dd')
            .format(DateTime.now());

    AttendanceModel? todayAttendance;
    for (final item in histories) {
      if (item.checkIn.startsWith(todayPrefix)) {
        todayAttendance = item;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      if (todayAttendance == null) {
        todayStatus = 'Belum Absen';
      } else if (todayAttendance.checkOut == null) {
        todayStatus = 'Sudah Masuk';
      } else {
        todayStatus = 'Sudah Pulang';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GeoPresence",
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DashboardCard(
              title: "Status Hari Ini",
              value: todayStatus,
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  MenuCard(
                    title: "Absensi",
                    icon:
                        Icons.fingerprint,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/attendance',
                      );

                      loadTodayStatus();
                    },
                  ),

                  MenuCard(
                    title: "Riwayat",
                    icon: Icons.history,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/history',
                      );
                    },
                  ),

                  MenuCard(
                    title: "Profil",
                    icon: Icons.person,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/profile',
                      );
                    },
                  ),

                  MenuCard(
                    title: "Logout",
                    icon: Icons.logout,
                    onTap: () async {
                      await StorageService()
                          .logout();

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
