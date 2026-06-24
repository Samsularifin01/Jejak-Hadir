import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/attendance_model.dart';
import '../../../models/user_model.dart';
import '../../Profile/controllers/profile_controller.dart';
import '../controllers/attendance_controller.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Position? position;
  String? locationError;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isMapReady = false;

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  UserModel? _user;
  AttendanceModel? _todayAttendance;
  bool _isLoading = true;

  static const int _onTimeHour = 7;
  static const int _onTimeMinute = 30;
  static const int _lateHour = 9;
  static const int _lateMinute = 0;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    getLocation();
    _loadUserAndAttendance();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> getLocation() async {
    try {
      final currentPosition = await LocationService().getCurrentLocation();
      if (!mounted) return;
      setState(() {
        position = currentPosition;
        locationError = null;
      });
      if (_isMapReady) {
        _mapController.move(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          16.0,
        );
      }
      _startLocationUpdates();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        locationError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (Position newPosition) {
        if (!mounted) return;
        setState(() {
          position = newPosition;
          locationError = null;
        });
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  Future<void> _loadUserAndAttendance() async {
    final userId = await StorageService().getUserId();
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final userResult = await ProfileController().getUserById(userId);
    AttendanceModel? todayAtt =
        await AttendanceController().getActiveAttendanceByUser(userId);

    if (todayAtt == null) {
      final histories =
          await AttendanceController().getAttendanceByUser(userId);
      final todayPrefix = DateFormat('yyyy-MM-dd').format(DateTime.now());
      for (final item in histories) {
        if (item.checkIn.startsWith(todayPrefix)) {
          todayAtt = item;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _user = userResult;
      _todayAttendance = todayAtt;
      _isLoading = false;
    });
  }

  String _getAttendanceStatus() {
    if (_todayAttendance == null) return 'Belum Hadir';
    if (_todayAttendance!.checkOut != null) return 'Selesai';
    return _todayAttendance!.status;
  }

  Color _getStatusColor() {
    switch (_getAttendanceStatus()) {
      case 'Hadir':
        return Colors.green;
      case 'Terlambat':
        return Colors.orange;
      case 'Selesai':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (_getAttendanceStatus()) {
      case 'Hadir':
        return Icons.check_circle_rounded;
      case 'Terlambat':
        return Icons.warning_rounded;
      case 'Selesai':
        return Icons.task_alt_rounded;
      default:
        return Icons.highlight_off_rounded;
    }
  }

  bool get _canCheckIn => _todayAttendance == null;
  bool get _canCheckOut =>
      _todayAttendance != null && _todayAttendance!.checkOut == null;

  String _formatLiveTime() => DateFormat('HH:mm:ss').format(_now);

  String _formatDate() {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final day = days[_now.weekday - 1];
    final month = months[_now.month - 1];
    return '$day, ${_now.day} $month ${_now.year}';
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

  String _checkInSubtitle() {
    if (_todayAttendance != null) {
      return 'Sudah absen pukul ${_formatTime(_todayAttendance!.checkIn)}';
    }
    return 'Catat kehadiran Anda sekarang';
  }

  String _checkOutSubtitle() {
    if (_todayAttendance?.checkOut != null) {
      return 'Sudah keluar pukul ${_formatTime(_todayAttendance!.checkOut)}';
    }
    if (_todayAttendance == null) return 'Absen masuk terlebih dahulu';
    return 'Catat waktu pulang Anda';
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = position != null;
    final primaryColor = Theme.of(context).primaryColor;
    final statusColor = _getStatusColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 165,
                  pinned: true,
                  backgroundColor: const Color(0xFF1A56DB),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A56DB), Color(0xFF0D3A9E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'PRESENSI SISWA',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded,
                                            color: Colors.white, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatLiveTime(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: const Text(
                    'Presensi Siswa',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF1A56DB),
                                child: Text(
                                  _user != null ? _getInitials(_user!.fullname) : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user?.fullname ?? 'Siswa',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _user?.email ?? '-',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(_getStatusIcon(),
                                        color: statusColor, size: 20),
                                    const SizedBox(height: 3),
                                    Text(
                                      _getAttendanceStatus(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildTimeCard(
                              label: 'Masuk',
                              time: _formatTime(_todayAttendance?.checkIn),
                              icon: Icons.login_rounded,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            _buildTimeCard(
                              label: 'Keluar',
                              time: _formatTime(_todayAttendance?.checkOut),
                              icon: Icons.logout_rounded,
                              color: Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 210,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: hasLocation
                                        ? LatLng(position!.latitude,
                                            position!.longitude)
                                        : const LatLng(-6.200000, 106.816666),
                                    initialZoom: 16.0,
                                    onMapReady: () {
                                      _isMapReady = true;
                                      if (position != null) {
                                        _mapController.move(
                                          LatLng(position!.latitude,
                                              position!.longitude),
                                          16.0,
                                        );
                                      }
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.jejak_hadir',
                                    ),
                                    if (hasLocation)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(position!.latitude,
                                                position!.longitude),
                                            width: 50,
                                            height: 50,
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 42,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                if (!hasLocation && locationError == null)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                if (hasLocation)
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: FloatingActionButton.small(
                                      heroTag: 'recenter_map',
                                      onPressed: () {
                                        _mapController.move(
                                          LatLng(position!.latitude,
                                              position!.longitude),
                                          16.0,
                                        );
                                      },
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      child: const Icon(Icons.my_location),
                                    ),
                                  ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          hasLocation
                                              ? Icons.gps_fixed
                                              : Icons.gps_not_fixed,
                                          size: 13,
                                          color: hasLocation
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasLocation
                                              ? 'GPS Aktif'
                                              : locationError != null
                                                  ? 'GPS Error'
                                                  : 'Mencari GPS...',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: hasLocation
                                                ? Colors.green
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          label: 'Absen Masuk',
                          subtitle: _checkInSubtitle(),
                          icon: Icons.login_rounded,
                          color: const Color(0xFF1A56DB),
                          enabled: _canCheckIn,
                          onTap: () async {
                            await Navigator.pushNamed(context, '/checkin');
                            _loadUserAndAttendance();
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildActionButton(
                          label: 'Absen Keluar',
                          subtitle: _checkOutSubtitle(),
                          icon: Icons.logout_rounded,
                          color: const Color(0xFFDC2626),
                          enabled: _canCheckOut,
                          onTap: () async {
                            await Navigator.pushNamed(context, '/checkout');
                            _loadUserAndAttendance();
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ketentuan Kehadiran',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A56DB),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildRuleRow(
                                Icons.check_circle_rounded,
                                Colors.green,
                                'Hadir',
                                'Check-in sebelum 0$_onTimeHour:${_onTimeMinute.toString().padLeft(2, '0')} WIB',
                              ),
                              const SizedBox(height: 4),
                              _buildRuleRow(
                                Icons.warning_rounded,
                                Colors.orange,
                                'Terlambat',
                                '0$_onTimeHour:${_onTimeMinute.toString().padLeft(2, '0')} - 0$_lateHour:${_lateMinute.toString().padLeft(2, '0')} WIB',
                              ),
                              const SizedBox(height: 4),
                              _buildRuleRow(
                                Icons.cancel_rounded,
                                Colors.red,
                                'Tidak Hadir',
                                'Setelah 0$_lateHour:${_lateMinute.toString().padLeft(2, '0')} WIB',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: child,
    );
  }

  Widget _buildTimeCard({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: _buildCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        time == '--:--' ? Colors.grey[400] : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final effectiveColor = enabled ? color : Colors.grey[400]!;
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleRow(
      IconData icon, Color color, String title, String desc) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
