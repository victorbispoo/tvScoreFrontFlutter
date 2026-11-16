import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

void main() {
  test(
    'public recovery preserves session and returns backend message',
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
                  'message': 'Se houver uma conta, enviaremos instruções.',
                },
              ),
            );
          },
        ),
      );
      expect(
        await api.requestPasswordRecovery(' USER@example.com '),
        'Se houver uma conta, enviaremos instruções.',
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
            expect(options.data, {
              'token': 'opaque+/=',
              'novaSenha': ' senha nova ',
            });
            handler.resolve(Response(requestOptions: options, statusCode: 204));
          },
        ),
      );
      await api.resetPassword('opaque+/=', ' senha nova ');
      expect(ApiService.token, 'session');
      await expectLater(
        api.resetPassword('', 'senha nova'),
        throwsFormatException,
      );
      await expectLater(
        api.resetPassword('opaque', 'á' * 37),
        throwsFormatException,
      );
      await expectLater(
        api.resetPassword('opaque', '1234567'),
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
      api.resetPassword('opaque', 'senha nova'),
      throwsFormatException,
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
}
