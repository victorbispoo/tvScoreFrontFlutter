import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

String tokenWithExpiration(num expiration) {
  String encode(Map<String, dynamic> data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.${encode({'sub': 'ana@teste.com', 'exp': expiration})}.test';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  late ApiService api;
  late String validToken;

  Future<void> login() async {
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/auth/login');
          expect(options.data, {
            'email': 'ana@teste.com',
            'senha': 'senha-de-teste',
          });
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'token': validToken,
                'email': 'ana@teste.com',
                'nome': 'Ana',
              },
            ),
          );
        },
      ),
    );
    await api.loginApi(' ANA@TESTE.COM ', 'senha-de-teste');
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    api = ApiService();
    await api.logout();
    validToken = tokenWithExpiration(
      DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
          1000,
    );
  });

  test('login persiste a sessão sem guardar a senha', () async {
    await login();
    expect(ApiService.token, validToken);
    final values = await storage.readAll();
    expect(values, hasLength(1));
    expect(jsonDecode(values.values.single), {
      'token': validToken,
      'email': 'ana@teste.com',
      'name': 'Ana',
    });
    expect(values.values.single, isNot(contains('senha-de-teste')));
  });

  test('restaura sessão, perfil e biblioteca depois de reiniciar', () async {
    await login();
    const content = {'id': '1', 'type': 'movie', 'title': 'Teste'};
    await api.toggleSaved(content);
    await api.saveReview(content, 9, 'Muito bom');
    await api.updateName('Ana Silva');
    ApiService.token = null;
    await api.open('outra@teste.com', 'Outra conta');

    expect(await ApiService().restoreSession(), isTrue);
    expect(ApiService.token, validToken);
    expect(ApiService.userEmail, 'ana@teste.com');
    expect(ApiService.userName, 'Ana Silva');
    expect(ApiService.savedContents.single, content);
    expect(ApiService.reviews.single.rating, 9);
  });

  test('sem sessão salva retorna ao login e limpa a memória', () async {
    ApiService.token = validToken;
    await api.open('outra@teste.com', 'Outra conta');
    expect(await api.restoreSession(), isFalse);
    expect(ApiService.token, isNull);
    expect(ApiService.userEmail, isEmpty);
    expect(ApiService.userName, isEmpty);
  });

  for (final scenario in ['expirado', 'malformado', 'sem expiração']) {
    test('descarta token $scenario ao abrir o app', () async {
      await login();
      final values = await storage.readAll();
      final session = jsonDecode(values.values.single) as Map<String, dynamic>;
      session['token'] = switch (scenario) {
        'expirado' => tokenWithExpiration(
          DateTime.now()
                  .subtract(const Duration(seconds: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        ),
        'sem expiração' => 'e30.e30.test',
        _ => 'token-invalido',
      };
      await storage.write(key: values.keys.single, value: jsonEncode(session));

      expect(await api.restoreSession(), isFalse);
      expect(ApiService.token, isNull);
      expect(ApiService.userEmail, isEmpty);
      expect(await storage.readAll(), isEmpty);
    });
  }

  test('sessão corrompida não impede a inicialização', () async {
    await login();
    final key = (await storage.readAll()).keys.single;
    await storage.write(key: key, value: '{invalid');
    expect(await api.restoreSession(), isFalse);
    expect(ApiService.token, isNull);
    expect(await storage.readAll(), isEmpty);
  });

  test('sair impede restaurar a sessão e preserva a biblioteca', () async {
    await login();
    const content = {'id': '1', 'title': 'Teste'};
    await api.toggleSaved(content);
    await api.logout();
    expect(await storage.readAll(), isEmpty);
    expect(ApiService.token, isNull);
    expect(ApiService.savedContents, isEmpty);
    expect(await ApiService().restoreSession(), isFalse);
    await api.open('ana@teste.com', 'Ana');
    expect(ApiService.savedContents.single, content);
  });

  test('login recusado não mantém uma sessão anterior', () async {
    await login();
    api.dio.interceptors.clear();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'mensagem': 'Credenciais inválidas.'},
            ),
          ),
        ),
      ),
    );
    await expectLater(
      api.loginApi('ana@teste.com', 'senha-errada'),
      throwsA(isA<FormatException>()),
    );
    expect(await storage.readAll(), isEmpty);
    expect(ApiService.token, isNull);
    expect(ApiService.userEmail, isEmpty);
  });
}
