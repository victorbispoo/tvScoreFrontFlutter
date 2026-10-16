import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

class AppSearchController extends ChangeNotifier {
  final queryController = TextEditingController();
  String _query = '';

  String get query => _query;
  bool get hasQuery => _query.isNotEmpty;

  void onChanged(String value) {
    _query = value.trim();
    notifyListeners();
  }

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  final _api= ApiService();
  Timer? _debounce;
  int _buscaAtual = 0;

  List<Map<String, String>> _resultados = [];
  bool _isLoading = false;
  String? _error;
}
