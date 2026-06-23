import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../models/user_model.dart';

class ProfileRepository {
  Future<UserModel?> getUserById(
      int userId) async {
    final Database db =
        await DatabaseHelper.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(
        result.first,
      );
    }

    return null;
  }

  Future<int> updateProfile(
      UserModel user) async {
    final Database db =
        await DatabaseHelper.database;

    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}