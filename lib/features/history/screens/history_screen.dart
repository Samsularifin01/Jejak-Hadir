import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/attendance_model.dart';
import '../controllers/history_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryController _controller = HistoryController();
  List<AttendanceModel> histories = [];
  bool isLoading = true;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final userId = await StorageService().getUserId();

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        currentUserId = null;
        histories = [];
        isLoading = false;
      });
      return;
    }

    final result = await _controller.getHistory(userId);

    if (!mounted) return;

    setState(() {
      currentUserId = userId;
      histories = result;
      isLoading = false;
    });
  }

  Future<void> _showAttendanceFormDialog([AttendanceModel? attendance]) async {
    final isEditing = attendance != null;
    final userId = currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID tidak ditemukan. Silakan login kembali.")),
      );
      return;
    }

    DateTime selectedDate = isEditing
        ? DateTime.parse(attendance.checkIn)
        : DateTime.now();
    
    TimeOfDay selectedCheckInTime = isEditing
        ? TimeOfDay.fromDateTime(DateTime.parse(attendance.checkIn))
        : TimeOfDay.now();

    bool hasCheckOut = isEditing && attendance.checkOut != null;
    TimeOfDay selectedCheckOutTime = isEditing && attendance.checkOut != null
        ? TimeOfDay.fromDateTime(DateTime.parse(attendance.checkOut!))
        : const TimeOfDay(hour: 17, minute: 0);

    String status = isEditing ? attendance.status : 'Hadir';
    final addressController = TextEditingController(
      text: isEditing ? attendance.address : 'Presensi Manual (Input)',
    );

    final statusOptions = ['Hadir', 'Terlambat', 'Selesai', 'Izin', 'Sakit', 'Alpa'];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEditing ? "Edit Presensi" : "Tambah Presensi",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tanggal Presensi",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogCtx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMMM yyyy').format(selectedDate)),
                            const Icon(Icons.calendar_month, color: Colors.blueAccent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      "Jam Masuk (Check In)",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: dialogCtx,
                          initialTime: selectedCheckInTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedCheckInTime = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedCheckInTime.format(dialogCtx)),
                            const Icon(Icons.access_time_rounded, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sudah Check Out?",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Switch(
                          value: hasCheckOut,
                          onChanged: (val) {
                            setDialogState(() {
                              hasCheckOut = val;
                              if (val && (status == 'Hadir' || status == 'Terlambat')) {
                                status = 'Selesai';
                              } else if (!val && status == 'Selesai') {
                                status = 'Hadir';
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (hasCheckOut) ...[
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: dialogCtx,
                            initialTime: selectedCheckOutTime,
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedCheckOutTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedCheckOutTime.format(dialogCtx)),
                              const Icon(Icons.access_time_rounded, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text(
                      "Status Presensi",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: status,
                          isExpanded: true,
                          items: statusOptions.map((String opt) {
                            return DropdownMenuItem<String>(
                              value: opt,
                              child: Text(opt),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setDialogState(() {
                                status = newVal;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      "Detail Lokasi / Alamat",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Masukkan lokasi presensi...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (addressController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        const SnackBar(content: Text("Alamat tidak boleh kosong")),
                      );
                      return;
                    }

                    final dtIn = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedCheckInTime.hour,
                      selectedCheckInTime.minute,
                    );
                    final checkInStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(dtIn);

                    String? checkOutStr;
                    if (hasCheckOut) {
                      final dtOut = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedCheckOutTime.hour,
                        selectedCheckOutTime.minute,
                      );
                      
                      if (dtOut.isBefore(dtIn)) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          const SnackBar(content: Text("Jam keluar harus setelah jam masuk")),
                        );
                        return;
                      }
                      checkOutStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(dtOut);
                    }

                    final newAttendance = AttendanceModel(
                      id: isEditing ? attendance.id : null,
                      userId: userId,
                      checkIn: checkInStr,
                      checkOut: checkOutStr,
                      latitude: isEditing ? attendance.latitude : 0.0,
                      longitude: isEditing ? attendance.longitude : 0.0,
                      address: addressController.text.trim(),
                      status: status,
                      createdAt: isEditing ? attendance.createdAt : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                    );

                    Navigator.pop(dialogCtx);

                    try {
                      if (isEditing) {
                        await _controller.updateAttendance(newAttendance);
                      } else {
                        await _controller.addAttendance(newAttendance);
                      }
                      
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing
                              ? "Presensi berhasil diperbarui"
                              : "Presensi berhasil ditambahkan"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      loadHistory();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Terjadi kesalahan: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Simpan", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(int attendanceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Hapus Presensi",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Apakah Anda yakin ingin menghapus data presensi ini? Tindakan ini tidak dapat dibatalkan.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _controller.deleteAttendance(attendanceId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Presensi berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
        loadHistory();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus presensi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDayNum(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd').format(dt);
    } catch (e) {
      return '--';
    }
  }

  String _getMonthStr(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final monthIndex = dt.month;
      const months = [
        'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
        'JUL', 'AGU', 'SEP', 'OKT', 'NOP', 'DES'
      ];
      if (monthIndex >= 1 && monthIndex <= 12) {
        return months[monthIndex - 1];
      }
      return 'MMM';
    } catch (e) {
      return 'MMM';
    }
  }

  String _getDayName(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final dayNameEn = DateFormat('EEEE').format(dt);
      
      switch (dayNameEn) {
        case 'Monday': return 'Senin';
        case 'Tuesday': return 'Selasa';
        case 'Wednesday': return 'Rabu';
        case 'Thursday': return 'Kamis';
        case 'Friday': return 'Jumat';
        case 'Saturday': return 'Sabtu';
        case 'Sunday': return 'Minggu';
        default: return dayNameEn;
      }
    } catch (e) {
      return 'Hari';
    }
  }

  String _getYear(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('yyyy').format(dt);
    } catch (e) {
      return '';
    }
  }

  String _getTimeOnly(String? dateStr) {
    if (dateStr == null) return '--:--';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: loadHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "Belum Ada Riwayat Presensi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tarik ke bawah untuk menyegarkan halaman",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: histories.length,
        itemBuilder: (context, index) {
          final item = histories[index];
          final isCompleted = item.checkOut != null;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      // Date Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _getDayNum(item.checkIn),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            Text(
                              _getMonthStr(item.checkIn),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Day Name & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDayName(item.checkIn),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getYear(item.checkIn),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isCompleted ? Colors.green : Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCompleted ? "Selesai" : "Masuk",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? Colors.green[800] : Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              // Check In Column
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.login_rounded, size: 16, color: Colors.green[600]),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Check In",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _getTimeOnly(item.checkIn),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Check Out Column
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.logout_rounded, size: 16, color: Colors.red[600]),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Check Out",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _getTimeOnly(item.checkOut),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isCompleted ? Colors.black : Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Location Detail Row
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Detail Lokasi",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.address,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                          height: 1.3,
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () => _showAttendanceFormDialog(item),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text(
                                  "Edit",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () => _confirmDelete(item.id!),
                                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                label: const Text(
                                  "Hapus",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Riwayat Presensi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : histories.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[800],
        onPressed: () => _showAttendanceFormDialog(),
        icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
        label: const Text(
          "Tambah Presensi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
