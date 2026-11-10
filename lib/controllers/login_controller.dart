import 'package:flutter/material.dart';

import '../services/api_services.dart';

class LoginController extends ChangeNotifier {
  LoginController({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  bool _disposed = false;

  Future<bool> submit() async {
    if (_disposed || isLoading) return false;
    errorMessage = null;
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.loginApi(
        emailController.text.trim(),
        passwordController.text,
      );
      return !_disposed;
    } on FormatException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (error, stackTrace) {
      debugPrint('Falha ao carregar os dados após o login: $error');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = 'Não foi possível acessar seus dados. Tente novamente.';
      return false;
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
