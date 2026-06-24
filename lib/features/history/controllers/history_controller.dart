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

  Future<int> addAttendance(
      AttendanceModel attendance) async {
    return await _repository.insertAttendance(
      attendance,
    );
  }

  Future<int> updateAttendance(
      AttendanceModel attendance) async {
    return await _repository.updateAttendance(
      attendance,
    );
  }

  Future<int> deleteAttendance(int id) async {
    return await _repository.deleteAttendance(
      id,
    );
  }
}