import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class DatabaseService {
  Future<Database> get db async =>
      await DatabaseHelper.database;

  Future<int> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final database = await db;
    return await database.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> getAll(
      String table) async {
    final database = await db;
    return await database.query(table);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data,
    int id,
  ) async {
    final database = await db;

    return await database.update(
      table,
      data,
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<int> delete(
    String table,
    int id,
  ) async {
    final database = await db;

    return await database.delete(
      table,
      where: 'id=?',
      whereArgs: [id],
    );
  }
}