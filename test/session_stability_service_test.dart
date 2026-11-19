import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/controllers/login_controller.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

import 'auth_session_test.dart' show tokenWithExpiration;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ApiService().logout();
  });
  tearDown(() => ApiService().logout());

  test(
    'redefinição de senha pendente não encerra uma sessão iniciada depois',
    () async {
      final api = ApiService();
      ApiService.token = 'conta-a';
      final started = Completer<void>();
      final release = Completer<void>();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            expect(options.headers['Authorization'], isNull);
            started.complete();
            await release.future;
            handler.resolve(Response(requestOptions: options, statusCode: 204));
          },
        ),
      );
      final pending = api.resetPassword('a' * 43, 'nova-senha');
      await started.future;
      await api.logout();
      ApiService.token = 'conta-b';
      release.complete();
      await pending;
      expect(ApiService.token, 'conta-b');
    },
  );

  test(
    'comentários e resumo continuam públicos antes e depois de sair',
    () async {
      final api = ApiService();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.headers['Authorization'], isNull);
            handler.resolve(
              Response(
                requestOptions: options,
                data: options.path.endsWith('/paginadas')
                    ? {'content': [], 'totalPages': 0, 'totalElements': 0}
                    : options.path.endsWith('/resumo')
                    ? {'totalAvaliacoes': 0, 'media': null}
                    : [],
              ),
            );
          },
        ),
      );
      for (final token in [null, 'conta-a', null]) {
        if (token == null) {
          await api.logout();
        } else {
          ApiService.token = token;
        }
        expect((await api.getContentReviewsPage(1, 'MOVIE')).reviews, isEmpty);
        expect(await api.getContentReviews(1, 'MOVIE'), isEmpty);
        expect(
          (await api.getContentReviewSummary(1, 'MOVIE'))['totalAvaliacoes'],
          0,
        );
      }
    },
  );

  test(
    'fechar o login pendente não autentica depois da saída da tela',
    () async {
      final api = ApiService();
      final controller = LoginController(apiService: api);
      controller.emailController.text = 'a@teste.com';
      controller.passwordController.text = 'senha';
      final started = Completer<void>();
      final release = Completer<void>();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            started.complete();
            await release.future;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'token': 'conta-a',
                  'email': 'a@teste.com',
                  'nome': 'Conta A',
                  'fotoUrl': null,
                },
              ),
            );
          },
        ),
      );
      final pending = controller.submit();
      await started.future;
      controller.dispose();
      release.complete();
      expect(await pending, isFalse);
      expect(ApiService.hasSession, isFalse);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    },
  );

  test('401 de requisição privada antiga não apaga sessão nova', () async {
    final api = ApiService();
    ApiService.token = 'conta-a';
    final started = Completer<void>();
    final release = Completer<void>();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          started.complete();
          await release.future;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: options, statusCode: 401),
            ),
            true,
          );
        },
      ),
    );
    final checked = expectLater(
      api.getFavorites(),
      throwsA(isA<DioException>()),
    );
    await started.future;
    await api.logout();
    ApiService.token = 'conta-b';
    release.complete();
    await checked;
    expect(ApiService.token, 'conta-b');
  });

  test('respostas públicas não invalidam sessão nem exigem JWT', () async {
    final api = ApiService();
    ApiService.token = 'conta-a';
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.headers['Authorization'], isNull);
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: options, statusCode: 401),
            ),
            true,
          );
        },
      ),
    );
    await expectLater(
      api.getContentReviewsPage(1, 'MOVIE'),
      throwsA(isA<DioException>()),
    );
    expect(ApiService.token, 'conta-a');
  });

  test('JWT expirado não autoriza chamadas privadas', () async {
    final api = ApiService();
    ApiService.token = tokenWithExpiration(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 - 1,
    );
    var calls = 0;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls++;
          handler.resolve(Response(requestOptions: options, data: []));
        },
      ),
    );
    expect(ApiService.hasSession, isFalse);
    await expectLater(api.getFavorites(), throwsStateError);
    expect(calls, 0);
  });

  test('401 privado encerra a sessão sem bloquear leituras públicas', () async {
    final api = ApiService();
    ApiService.token = 'conta-a';
    ApiService.userName = 'Conta A';
    ApiService.savedContents = [
      const {'id': '1', 'type': 'MOVIE'},
    ];
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/favoritos') {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(requestOptions: options, statusCode: 401),
              ),
              true,
            );
          } else {
            expect(options.headers['Authorization'], isNull);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'content': [], 'totalPages': 0, 'totalElements': 0},
              ),
            );
          }
        },
      ),
    );
    await expectLater(api.getFavorites(), throwsA(isA<DioException>()));
    expect(ApiService.token, isNull);
    expect(ApiService.userName, isEmpty);
    expect(ApiService.savedContents, isEmpty);
    expect((await api.getContentReviewsPage(1, 'MOVIE')).reviews, isEmpty);
  });

  for (final status in [200, 401]) {
    test(
      'resposta $status de login antigo não substitui a conta atual',
      () async {
        final api = ApiService();
        final started = Completer<void>();
        final release = Completer<void>();
        api.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final email = options.data['email'];
              if (email == 'a@teste.com') {
                started.complete();
                await release.future;
                if (status == 401) {
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      type: DioExceptionType.badResponse,
                      response: Response(
                        requestOptions: options,
                        statusCode: 401,
                      ),
                    ),
                  );
                  return;
                }
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'token': email,
                    'email': email,
                    'nome': email,
                    'fotoUrl': null,
                  },
                ),
              );
            },
          ),
        );
        final pending = api.loginApi('a@teste.com', 'senha');
        final checked = expectLater(pending, throwsA(anything));
        await started.future;
        await api.loginApi('b@teste.com', 'senha');
        release.complete();
        await checked;
        expect(ApiService.token, 'b@teste.com');
        expect(ApiService.userEmail, 'b@teste.com');
        expect(
          await const FlutterSecureStorage().read(key: 'tv_score_session'),
          contains('b@teste.com'),
        );
      },
    );
  }

  test('logout impede um login pendente de restaurar a sessão', () async {
    final api = ApiService();
    final started = Completer<void>();
    final release = Completer<void>();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          started.complete();
          await release.future;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'token': 'conta-a',
                'email': 'a@teste.com',
                'nome': 'Conta A',
                'fotoUrl': null,
              },
            ),
          );
        },
      ),
    );
    final pending = api.loginApi('a@teste.com', 'senha');
    final checked = expectLater(pending, throwsA(anything));
    await started.future;
    await api.logout();
    release.complete();
    await checked;
    expect(ApiService.hasSession, isFalse);
    expect(ApiService.userEmail, isEmpty);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  for (final resource in [
    'generos',
    'conteudos-preferidos',
    'conteudos-preferidos/opcoes',
  ]) {
    test(
      'preferências pendentes de $resource são descartadas ao trocar conta',
      () async {
        final api = ApiService();
        ApiService.token = 'conta-a';
        final started = Completer<void>();
        final release = Completer<void>();
        api.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              started.complete();
              await release.future;
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'generos': [],
                    'conteudos': [],
                    'results': [],
                    'page': 1,
                    'total_pages': 1,
                  },
                ),
              );
            },
          ),
        );
        final pending = switch (resource) {
          'generos' => api.getPreferredGenres(),
          'conteudos-preferidos' => api.getPreferredContents(),
          _ => api.getPreferredContentOptions(),
        };
        final checked = expectLater(pending, throwsStateError);
        await started.future;
        await api.logout();
        ApiService.token = 'conta-b';
        release.complete();
        await checked;
        expect(ApiService.token, 'conta-b');
      },
    );
  }

  test(
    'troca de senha pendente da conta anterior não encerra nova sessão',
    () async {
      final api = ApiService();
      ApiService.token = 'conta-a';
      final started = Completer<void>();
      final release = Completer<void>();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            started.complete();
            await release.future;
            handler.resolve(Response(requestOptions: options, statusCode: 204));
          },
        ),
      );
      final pending = api.changePassword('senha-atual', 'nova-senha');
      final checked = expectLater(pending, throwsStateError);
      await started.future;
      await api.logout();
      ApiService.token = 'conta-b';
      release.complete();
      await checked;
      expect(ApiService.token, 'conta-b');
    },
  );
}
