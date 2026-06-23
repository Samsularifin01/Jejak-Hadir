import '../../../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';

class AttendanceController {
  final AttendanceRepository _repository =
      AttendanceRepository();

  Future<int> checkIn(
      AttendanceModel attendance) async {
    return await _repository.checkIn(
      attendance,
    );
  }

  Future<int> checkOut(
      int attendanceId,
      String checkOut) async {
    return await _repository.checkOut(
      attendanceId,
      checkOut,
    );
  }

  Future<List<AttendanceModel>>
      getAttendanceByUser(
          int userId) async {
    return await _repository
        .getAttendanceByUser(userId);
  }

  Future<AttendanceModel?>
      getActiveAttendanceByUser(
          int userId) async {
    return await _repository
        .getActiveAttendanceByUser(userId);
  }
}
