import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const movie = {
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

  test('salva a lista, avaliação e nome ao reabrir a conta', () async {
    await api.toggleSaved(movie);
    await api.saveReview(movie, 9, '  Muito bom  ');
    await api.updateName('José');
    await api.open('ana@teste.com', 'Ana');
    expect(ApiService.savedMovies, isEmpty);
    expect(ApiService.reviews, isEmpty);
    await api.open('jose@teste.com', 'Nome padrão');
    expect(ApiService.userName, 'José');
    expect(ApiService.savedMovies.single, movie);
    expect(ApiService.reviews.single.rating, 9);
    expect(ApiService.reviews.single.comment, 'Muito bom');
  });

  test(
    'editar substitui a avaliação e excluir remove do armazenamento',
    () async {
      await api.saveReview(movie, 7, 'Bom');
      await api.saveReview(movie, 10, 'Excelente');
      expect(ApiService.reviews, hasLength(1));
      expect(ApiService.reviews.single.rating, 10);
      await api.deleteReview(ApiService.reviews.single);
      await api.toggleSaved(movie);
      await api.toggleSaved(movie);
      await api.open('jose@teste.com', 'José');
      expect(ApiService.reviews, isEmpty);
      expect(ApiService.savedMovies, isEmpty);
    },
  );

  test('recusa notas fora de 1 a 10', () async {
    await expectLater(api.saveReview(movie, 0, ''), throwsArgumentError);
    await expectLater(api.saveReview(movie, 11, ''), throwsArgumentError);
    expect(ApiService.reviews, isEmpty);
  });
}
