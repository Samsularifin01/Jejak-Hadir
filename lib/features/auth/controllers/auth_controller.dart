import '../../../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthController {
  final AuthRepository _repository =
      AuthRepository();

  Future<int> register(
      UserModel user) async {
    return await _repository.register(
      user,
    );
  }

  Future<UserModel?> login(
    String email,
    String password,
  ) async {
    return await _repository.login(
      email,
      password,
    );
  }
}