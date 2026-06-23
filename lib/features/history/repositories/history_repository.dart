import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../models/attendance_model.dart';

class HistoryRepository {
  Future<List<AttendanceModel>> getHistory(
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
}