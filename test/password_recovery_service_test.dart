import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/password_recovery_rules.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final token = 'a' * 43;
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('validação segue caracteres e limite em bytes do reset', () {
    for (final password in [
      '123456',
      ' 1234 ',
      'á' * 36,
      '𐐷abcde',
      '#*1234',
    ]) {
      expect(PasswordRecoveryRules.validatePassword(password), isNull);
    }
    for (final password in [
      '12345',
      '\u0085' * 6,
      'á' * 37,
      '𐐷abcd',
      'abcde😀',
      'abcde1️⃣',
    ]) {
      expect(PasswordRecoveryRules.validatePassword(password), isNotNull);
    }
  });

  test(
    'public recovery preserves session and uses an account-neutral message',
    () async {
      final api = ApiService();
      ApiService.token = 'session';
      api.dio.options.headers['Authorization'] = 'Bearer session';
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/auth/senha/recuperacao');
            expect(options.method, 'POST');
            expect(options.headers['Authorization'], isNull);
            expect(options.data, {'email': 'user@example.com'});
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 202,
                data: {
                  'message': 'Mensagem específica que não deve ser exibida.',
                },
              ),
            );
          },
        ),
      );
      expect(
        await api.requestPasswordRecovery(' USER@example.com '),
        'Se o e-mail estiver cadastrado, enviaremos as instruções de recuperação.',
      );
      expect(ApiService.token, 'session');
    },
  );

  test(
    'public reset sends opaque token and intact password without login',
    () async {
      final api = ApiService();
      ApiService.token = 'session';
      api.dio.options.headers['Authorization'] = 'Bearer session';
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/auth/senha/redefinicao');
            expect(options.headers['Authorization'], isNull);
            expect(options.data, {'token': token, 'novaSenha': ' senha nova '});
            handler.resolve(Response(requestOptions: options, statusCode: 204));
          },
        ),
      );
      await api.resetPassword(token, ' senha nova ');
      expect(ApiService.token, isNull);
      await expectLater(
        api.resetPassword('', 'senha nova'),
        throwsA(isA<InvalidRecoveryLink>()),
      );
      await expectLater(
        api.resetPassword(token, 'á' * 37),
        throwsFormatException,
      );
      await expectLater(
        api.resetPassword(token, '12345'),
        throwsFormatException,
      );
    },
  );

  test('400 maps invalid or expired reset token to safe message', () async {
    final api = ApiService();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 400),
            ),
          );
        },
      ),
    );
    await expectLater(
      api.resetPassword(token, 'senha nova'),
      throwsA(isA<InvalidRecoveryLink>()),
    );
  });

  test('reset distingue senha repetida de falha de rede', () async {
    final api = ApiService();
    var rejectedPassword = true;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: rejectedPassword
                  ? Response(
                      requestOptions: options,
                      statusCode: 400,
                      data: {
                        'mensagem': 'A nova senha deve ser diferente da atual.',
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
    await expectLater(
      api.resetPassword(token, '123456'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Escolha uma senha diferente da atual.',
        ),
      ),
    );
    rejectedPassword = false;
    await expectLater(
      api.resetPassword(token, '123456'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Não foi possível redefinir a senha. Tente novamente.',
        ),
      ),
    );
  });

  test(
    '429 respects seconds, HTTP date and blocks repeated requests',
    () async {
      final api = ApiService();
      var calls = 0;
      var header = '0';
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls++;
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 429,
                  headers: Headers.fromMap({
                    'retry-after': [header],
                  }),
                ),
              ),
            );
          },
        ),
      );
      await expectLater(
        api.requestPasswordRecovery('a@b.com'),
        throwsA(isA<RecoveryRateLimit>()),
      );
      header = '2';
      await expectLater(
        api.requestPasswordRecovery('a@b.com'),
        throwsA(isA<RecoveryRateLimit>()),
      );
      expect(api.recoveryRetryAt!.isAfter(DateTime.now()), isTrue);
      await expectLater(
        api.requestPasswordRecovery('a@b.com'),
        throwsA(isA<RecoveryRateLimit>()),
      );
      expect(calls, 2);
      // Expire the short interval before checking an HTTP date.
      await Future<void>.delayed(const Duration(seconds: 2));
      header = 'Wed, 01 Jan 2031 12:00:00 GMT';
      await expectLater(
        api.requestPasswordRecovery('a@b.com'),
        throwsA(isA<RecoveryRateLimit>()),
      );
      expect(api.recoveryRetryAt, DateTime.utc(2031, 1, 1, 12));
      await expectLater(
        api.requestPasswordRecovery('a@b.com'),
        throwsA(isA<RecoveryRateLimit>()),
      );
      expect(calls, 3);
    },
  );

  test('reset honors Retry-After without resending during cooldown', () async {
    final api = ApiService();
    var calls = 0;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls++;
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 429,
                headers: Headers.fromMap({
                  'retry-after': ['30'],
                }),
              ),
            ),
          );
        },
      ),
    );
    await expectLater(
      api.resetPassword(token, '123456'),
      throwsA(isA<RecoveryRateLimit>()),
    );
    await expectLater(
      api.resetPassword(token, '123456'),
      throwsA(isA<RecoveryRateLimit>()),
    );
    expect(api.resetRetryAt!.isAfter(DateTime.now()), isTrue);
    expect(calls, 1);
  });
}
