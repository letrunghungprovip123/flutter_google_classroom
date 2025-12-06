import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggerInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print(
        "➡️ RESPONSE [${response.statusCode}] ${response.requestOptions.uri}",
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print("❌ ERROR: ${err.response?.data}");
    }
    super.onError(err, handler);
  }
}
