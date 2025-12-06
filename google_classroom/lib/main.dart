import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_classroom/core/network/dio_client.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DioClient.instance.init(); // interceptor lúc này chắc chắn hoạt động

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Classroom LMS",
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
