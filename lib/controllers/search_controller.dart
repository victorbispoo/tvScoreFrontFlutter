import 'package:flutter/material.dart';

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
}
