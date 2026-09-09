import 'package:flutter/material.dart';

import '../services/api_services.dart';

class LoginController extends ChangeNotifier {
  LoginController({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  bool get canSubmit =>
      emailController.text.trim().isNotEmpty &&
      passwordController.text.isNotEmpty;

  void onChanged() => notifyListeners();

  Future<bool> submit() async {
    if (isLoading) return false;
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.login(
        emailController.text.trim(),
        passwordController.text,
      );
      return true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
