import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../features/shared/models/user_model.dart';

final userProfileProvider = FutureProvider<UserModel>((ref) async {
  final res = await DioClient.instance.dio.get('/auth/profile');
  return UserModel.fromJson(res.data['data']);
});
