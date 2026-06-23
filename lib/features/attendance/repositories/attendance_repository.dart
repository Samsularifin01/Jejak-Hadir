import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../models/attendance_model.dart';

class AttendanceRepository {
  Future<int> checkIn(
      AttendanceModel attendance) async {
    final Database db =
        await DatabaseHelper.database;

    return await db.insert(
      'attendances',
      attendance.toMap(),
    );
  }

  Future<List<AttendanceModel>>
      getAttendanceByUser(
          int userId) async {
    final Database db =
        await DatabaseHelper.database;

    final result = await db.query(
      'attendances',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    return result
        .map(
          (e) => AttendanceModel.fromMap(e),
        )
        .toList();
  }

  Future<AttendanceModel?> getActiveAttendanceByUser(
      int userId) async {
    final Database db =
        await DatabaseHelper.database;

    final result = await db.query(
      'attendances',
      where:
          'user_id = ? AND check_out IS NULL',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AttendanceModel.fromMap(
      result.first,
    );
  }

  Future<int> checkOut(
      int attendanceId,
      String checkOut) async {
    final Database db =
        await DatabaseHelper.database;

    return await db.update(
      'attendances',
      {
        'check_out': checkOut,
        'status': 'Selesai',
      },
      where: 'id=?',
      whereArgs: [attendanceId],
    );
  }
}
