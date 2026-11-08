import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const content = {
    'title': 'Filme de teste',
    'year': '2024',
    'score': '8.0',
    'genre': 'Drama',
  };
  late ApiService api;

  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  setUp(() async {
    await SharedPreferencesAsync().clear();
    api = ApiService();
    await api.open('jose@teste.com', 'José Silva');
  });

  test('preserva nome sem persistir favoritos ou avaliações', () async {
    ApiService.savedContents = [content];
    await api.updateName('José');
    await api.open('ana@teste.com', 'Ana');
    expect(ApiService.savedContents, isEmpty);
    expect(ApiService.reviews, isEmpty);
    await api.open('jose@teste.com', 'Nome padrão');
    expect(ApiService.userName, 'José');
    expect(ApiService.savedContents, isEmpty);
    final stored =
        jsonDecode(
              (await SharedPreferencesAsync().getString(
                'tv_score_library_jose@teste.com',
              ))!,
            )
            as Map<String, dynamic>;
    expect(stored.containsKey('saved'), isFalse);
    expect(stored.containsKey('reviews'), isFalse);
    expect(ApiService.reviews, isEmpty);
  });

  test('reabrir conta limpa as listas em memória', () async {
    ApiService.savedContents = [content];
    await api.open('jose@teste.com', 'José');
    expect(ApiService.reviews, isEmpty);
    expect(ApiService.savedContents, isEmpty);
  });

  test('remove favoritos antigos preservando os outros dados locais', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      'tv_score_library_jose@teste.com',
      jsonEncode({
        'name': 'José',
        'saved': [content],
        'reviews': [],
      }),
    );
    await api.open('jose@teste.com', 'Nome padrão');
    expect(ApiService.savedContents, isEmpty);
    expect(ApiService.userName, 'José');
    final stored =
        jsonDecode(
              (await preferences.getString('tv_score_library_jose@teste.com'))!,
            )
            as Map<String, dynamic>;
    expect(stored.containsKey('saved'), isFalse);
    expect(stored['name'], 'José');
    expect(stored.containsKey('reviews'), isFalse);
  });

  test('recusa notas fora de 0 a 10 e valores não finitos', () async {
    await expectLater(api.saveReview(content, -0.5, ''), throwsArgumentError);
    await expectLater(api.saveReview(content, 11, ''), throwsArgumentError);
    await expectLater(
      api.saveReview(content, double.nan, ''),
      throwsArgumentError,
    );
    await expectLater(
      api.saveReview(content, double.infinity, ''),
      throwsArgumentError,
    );
    expect(ApiService.reviews, isEmpty);
  });
}
