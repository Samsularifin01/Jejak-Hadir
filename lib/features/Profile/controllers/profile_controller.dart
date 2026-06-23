import '../../../models/user_model.dart';
import '../repositories/profile_repository.dart';

class ProfileController {
  final ProfileRepository _repository =
      ProfileRepository();

  Future<UserModel?> getUserById(
      int userId) async {
    return await _repository.getUserById(
      userId,
    );
  }

  Future<int> updateProfile(
      UserModel user) async {
    return await _repository.updateProfile(
      user,
    );
  }
}