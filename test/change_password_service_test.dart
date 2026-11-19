import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'tv_score_session': 'old'});
    ApiService.token = 'old-token';
  });
  test('204 envia senhas intactas e limpa sessão', () async {
    final api = ApiService();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'PUT');
          expect(options.path, '/usuarios/eu/senha');
          expect(options.headers['Authorization'], 'Bearer old-token');
          expect(options.data, {
            'senhaAtual': ' atual ',
            'novaSenha': ' nova senha ',
          });
          handler.resolve(Response(requestOptions: options, statusCode: 204));
        },
      ),
    );
    await api.changePassword(' atual ', ' nova senha ');
    expect(ApiService.token, isNull);
    expect(
      await const FlutterSecureStorage().read(key: 'tv_score_session'),
      isNull,
    );
  });
  for (final status in [400, 401, 403, 500]) {
    test('trata $status e invalida sessão apenas em 401', () async {
      final api = ApiService();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: status),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );
      await expectLater(
        api.changePassword('atual', 'nova senha'),
        throwsA(status == 401 ? isA<DioException>() : isA<FormatException>()),
      );
      expect(ApiService.token, status == 401 ? isNull : 'old-token');
    });
  }
  test('alteração aplica a política de recuperação antes do envio', () async {
    final api = ApiService();
    for (final next in ['á' * 4, 'á' * 37, '      ', 'senha😀', 'igualigual']) {
      await expectLater(
        api.changePassword('igualigual', next),
        throwsFormatException,
      );
    }
    var calls = 0;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls++;
          handler.resolve(Response(requestOptions: options, statusCode: 204));
        },
      ),
    );
    await api.changePassword('atual', '123456');
    // A successful password change ends the session; authenticate the next case.
    ApiService.token = 'old-token';
    await api.changePassword('atual', 'á' * 36);
    expect(calls, 2);
  });

  test('cadastro aplica a política de recuperação antes do envio', () async {
    final api = ApiService();
    var calls = 0;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls++;
          expect(options.path, '/auth/cadastrar');
          expect((options.data as Map)['senha'], 'áéíóúç');
          handler.resolve(Response(requestOptions: options, statusCode: 201));
        },
      ),
    );
    for (final password in ['á' * 4, 'á' * 37, '      ', 'senha😀']) {
      await expectLater(
        api.register('Maria', 'maria@example.com', password),
        throwsFormatException,
      );
    }
    await api.register('Maria', 'maria@example.com', 'áéíóúç');
    expect(calls, 1);
  });
}
