import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logger_interceptor.dart';

class DioClient {
  DioClient._();
  static final instance = DioClient._();

  late Dio dio;

  void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: "http://localhost:3000", // sửa thành API của bạn
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );

    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(LoggerInterceptor());
  }
}
