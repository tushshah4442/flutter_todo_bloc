import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/app_error.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SharedPreferences sharedPreferences;
  static const String keyIsLoggedIn = 'is_logged_in';

  // Hardcoded credentials as per assignment requirements
  static const String validEmail = 'admin@azodha.com';
  static const String validPassword = 'password123';

  AuthRepositoryImpl({required this.sharedPreferences});

  @override
  Future<void> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email == validEmail && password == validPassword) {
      await sharedPreferences.setBool(keyIsLoggedIn, true);
    } else {
      throw AppError('Invalid email or password');
    }
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove(keyIsLoggedIn);
  }

  @override
  Future<bool> checkLoginStatus() async {
    return sharedPreferences.getBool(keyIsLoggedIn) ?? false;
  }
}
