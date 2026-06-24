import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/attendance_model.dart';
import '../../../models/user_model.dart';
import '../../Profile/controllers/profile_controller.dart';
import '../../attendance/controllers/attendance_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceController _controller = AttendanceController();

  AttendanceModel? _todayAttendance;
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = await StorageService().getUserId();
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final user = await ProfileController().getUserById(userId);
    final histories = await _controller.getAttendanceByUser(userId);
    final todayPrefix = DateFormat('yyyy-MM-dd').format(DateTime.now());

    AttendanceModel? todayAtt;
    for (final item in histories) {
      if (item.checkIn.startsWith(todayPrefix)) {
        todayAtt = item;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _user = user;
      _todayAttendance = todayAtt;
      _isLoading = false;
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _getStatusLabel() {
    if (_todayAttendance == null) return 'Belum Hadir';
    if (_todayAttendance!.checkOut != null) return 'Sudah Pulang';
    return _todayAttendance!.status; // Hadir / Terlambat
  }

  Color _getStatusColor() {
    switch (_getStatusLabel()) {
      case 'Hadir':
        return Colors.green;
      case 'Terlambat':
        return Colors.orange;
      case 'Sudah Pulang':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (_getStatusLabel()) {
      case 'Hadir':
        return Icons.check_circle_rounded;
      case 'Terlambat':
        return Icons.warning_rounded;
      case 'Sudah Pulang':
        return Icons.task_alt_rounded;
      default:
        return Icons.highlight_off_rounded;
    }
  }

  String _formatDate() {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(dateStr));
    } catch (_) {
      return '--:--';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A56DB), Color(0xFF0D3A9E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                                    child: Text(
                                      _user != null
                                          ? _getInitials(_user!.fullname)
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Selamat Datang,',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          _user?.fullname ?? 'Siswa',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'SMK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Date chip
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Status Card ───────────────────────────────────
                          _buildStatusCard(),
                          const SizedBox(height: 24),

                          // ── Menu Title ────────────────────────────────────
                          const Text(
                            'Menu Utama',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Menu Grid ─────────────────────────────────────
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                            children: [
                              _buildMenuCard(
                                title: 'Presensi',
                                subtitle: 'Absen masuk & keluar',
                                icon: Icons.fingerprint_rounded,
                                color: const Color(0xFF1A56DB),
                                onTap: () async {
                                  await Navigator.pushNamed(
                                      context, '/attendance');
                                  _loadData();
                                },
                              ),
                              _buildMenuCard(
                                title: 'Riwayat',
                                subtitle: 'Rekap kehadiran',
                                icon: Icons.history_rounded,
                                color: const Color(0xFF7C3AED),
                                onTap: () =>
                                    Navigator.pushNamed(context, '/history'),
                              ),
                              _buildMenuCard(
                                title: 'Profil',
                                subtitle: 'Data diri siswa',
                                icon: Icons.person_rounded,
                                color: const Color(0xFF0891B2),
                                onTap: () =>
                                    Navigator.pushNamed(context, '/profile'),
                              ),
                              _buildMenuCard(
                                title: 'Keluar',
                                subtitle: 'Logout akun',
                                icon: Icons.logout_rounded,
                                color: const Color(0xFFDC2626),
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      title: const Text('Konfirmasi Logout'),
                                      content: const Text(
                                          'Apakah Anda yakin ingin keluar?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFDC2626),
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Ya, Keluar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await StorageService().logout();
                                    if (!context.mounted) return;
                                    Navigator.pushNamedAndRemoveUntil(
                                        context, '/login', (r) => false);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Status Card ───────────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor();
    final statusLabel = _getStatusLabel();
    final statusIcon = _getStatusIcon();
    final checkIn = _formatTime(_todayAttendance?.checkIn);
    final checkOut = _formatTime(_todayAttendance?.checkOut);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Status Kehadiran Hari Ini',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimeInfo(
                  Icons.login_rounded, 'Masuk', checkIn, Colors.green),
              const SizedBox(width: 16),
              Container(width: 1, height: 36, color: Colors.grey[200]),
              const SizedBox(width: 16),
              _buildTimeInfo(
                  Icons.logout_rounded, 'Keluar', checkOut, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(IconData icon, String label, String time, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(
                time,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: time == '--:--' ? Colors.grey[400] : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Menu Card ─────────────────────────────────────────────────────────────────

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
