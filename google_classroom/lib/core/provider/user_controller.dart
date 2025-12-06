import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/shared/models/user_model.dart';
import '../network/dio_client.dart';

class UserController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return null; // mặc định chưa load user
  }

  Future<void> fetchUser() async {
    state = const AsyncLoading();

    try {
      final res = await DioClient.instance.dio.get('/auth/profile');
      final user = UserModel.fromJson(res.data['data']);
      state = AsyncData(user);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  void clearUser() {
    state = const AsyncData(null);
  }
}

final userControllerProvider =
    AsyncNotifierProvider<UserController, UserModel?>(UserController.new);
