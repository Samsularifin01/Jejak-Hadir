import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String userIdKey = "user_id";

  Future<void> saveUserId(int id) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setInt(userIdKey, id);
  }

  Future<int?> getUserId() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getInt(userIdKey);
  }

  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.clear();
  }
}