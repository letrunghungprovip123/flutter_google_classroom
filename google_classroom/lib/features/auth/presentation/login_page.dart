import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_classroom/core/provider/user_controller.dart';
import '../../../routing/app_router.dart';
import '../../../core/storage /secure_storage.dart';
import '../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);

    try {
      final res = await DioClient.instance.dio.post(
        "/auth/login",
        data: {
          "username": userCtrl.text.trim(),
          "password": passCtrl.text.trim(),
        },
      );

      // ====== LẤY DỮ LIỆU ĐÚNG THEO API ======
      final token = res.data["data"]["token"];
      final role = res.data["data"]["user"]["role"];
      final username = res.data["data"]["user"]["username"];

      // ====== LƯU TOKEN + ROLE + USERNAME ======
      await SecureStorage.instance.write("token", token);
      await SecureStorage.instance.write("role", role);
      await SecureStorage.instance.write("username", username);

      await ref.read(userControllerProvider.notifier).fetchUser();
      if (!mounted) return;

      // ====== REDIRECT ======

      context.go(AppRoute.studentHome);
    } on DioException catch (e) {
      print(e.response?.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data["message"] ?? "Login failed")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 40),

              // Username field
              TextField(
                controller: userCtrl,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Password field
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const SizedBox(height: 22),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Please contact your instructor to get acccount!",
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.school_rounded,
            size: 50,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          "Welcome to our classroom",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Login to your classroom account",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
