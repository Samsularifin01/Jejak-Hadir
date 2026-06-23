import '../../../models/attendance_model.dart';
import '../repositories/history_repository.dart';

class HistoryController {
  final HistoryRepository _repository =
      HistoryRepository();

  Future<List<AttendanceModel>>
      getHistory(int userId) async {
    return await _repository.getHistory(
      userId,
    );
  }
}