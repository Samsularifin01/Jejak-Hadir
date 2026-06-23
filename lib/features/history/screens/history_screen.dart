import 'package:flutter/material.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/attendance_model.dart';
import '../controllers/history_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState
    extends State<HistoryScreen> {
  final HistoryController _controller =
      HistoryController();

  List<AttendanceModel> histories = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadHistory();
  }

  Future<void> loadHistory() async {
    final userId =
        await StorageService().getUserId();

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        histories = [];
        isLoading = false;
      });
      return;
    }

    final result =
        await _controller.getHistory(userId);

    if (!mounted) return;

    setState(() {
      histories = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Riwayat Presensi")),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : histories.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada riwayat presensi",
                  ),
                )
              : ListView.builder(
                  itemCount: histories.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final item =
                        histories[index];

                    return Card(
                      margin:
                          const EdgeInsets.all(
                        8,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.location_on,
                        ),
                        title: Text(
                          item.address,
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              "Check In : ${item.checkIn}",
                            ),
                            Text(
                              "Check Out : ${item.checkOut ?? '-'}",
                            ),
                            Text(
                              "Status : ${item.status}",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
