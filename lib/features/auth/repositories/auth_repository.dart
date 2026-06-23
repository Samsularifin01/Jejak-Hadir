import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../models/user_model.dart';

class AuthRepository {
  Future<int> register(
      UserModel user) async {
    final Database db =
        await DatabaseHelper.database;

    return await db.insert(
      'users',
      user.toMap(),
    );
  }

  Future<UserModel?> login(
    String email,
    String password,
  ) async {
    final Database db =
        await DatabaseHelper.database;

    final result = await db.query(
      'users',
      where:
          'email = ? AND password = ?',
      whereArgs: [
        email,
        password,
      ],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(
        result.first,
      );
    }

    return null;
  }
}