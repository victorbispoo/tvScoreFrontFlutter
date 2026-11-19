part of 'api_services.dart';

class RecoveryRateLimit implements Exception {
  const RecoveryRateLimit(this.retryAt);
  final DateTime retryAt;
}

class InvalidRecoveryLink implements Exception {
  const InvalidRecoveryLink();
}

extension AuthService on ApiService {
  static DateTime? _recoveryRetryAt;
  static DateTime? _resetRetryAt;
  static bool _requestingRecovery = false;

  DateTime? get recoveryRetryAt => _recoveryRetryAt;
  DateTime? get resetRetryAt => _resetRetryAt;

  static DateTime _retryAt(String? header) {
    final now = DateTime.now().toUtc();
    final seconds = int.tryParse(header ?? '');
    if (seconds != null && seconds >= 0) {
      return now.add(Duration(seconds: seconds));
    }
    final parts = RegExp(
      r'^\w{3}, (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
    ).firstMatch(header ?? '');
    if (parts != null) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months.indexOf(parts[2]!);
      if (month >= 0) {
        final date = DateTime.utc(
          int.parse(parts[3]!),
          month + 1,
          int.parse(parts[1]!),
          int.parse(parts[4]!),
          int.parse(parts[5]!),
          int.parse(parts[6]!),
        );
        return date.isAfter(now) ? date : now;
      }
    }
    return now.add(const Duration(seconds: 60));
  }

  Future<String> requestPasswordRecovery(String email) async {
    if (_recoveryRetryAt?.isAfter(DateTime.now()) ?? false) {
      throw RecoveryRateLimit(_recoveryRetryAt!);
    }
    if (_requestingRecovery) {
      throw const FormatException('Aguarde a solicitação em andamento.');
    }
    _requestingRecovery = true;
    try {
      final response = await dio.post(
        '/auth/senha/recuperacao',
        data: {'email': email.trim().toLowerCase()},
        options: Options(headers: {'Authorization': null}),
      );
      if (response.statusCode != 202) {
        throw const FormatException(
          'Não foi possível solicitar a recuperação. Tente novamente.',
        );
      }
      return 'Se o e-mail estiver cadastrado, enviaremos as instruções de recuperação.';
    } on DioException catch (error) {
      if (error.response?.statusCode == 429) {
        _recoveryRetryAt = _retryAt(
          error.response?.headers.value('retry-after'),
        );
        throw RecoveryRateLimit(_recoveryRetryAt!);
      }
      throw const FormatException(
        'Não foi possível solicitar a recuperação. Tente novamente.',
      );
    } finally {
      _requestingRecovery = false;
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    final session = ApiService._sessionVersion;
    if (!PasswordRecoveryRules.isValidToken(token)) {
      throw const InvalidRecoveryLink();
    }
    final validation = PasswordRecoveryRules.validatePassword(newPassword);
    if (validation != null) throw FormatException(validation);
    if (_resetRetryAt?.isAfter(DateTime.now()) ?? false) {
      throw RecoveryRateLimit(_resetRetryAt!);
    }
    try {
      final response = await dio.post(
        '/auth/senha/redefinicao',
        data: {'token': token, 'novaSenha': newPassword},
        options: Options(headers: {'Authorization': null}),
      );
      if (response.statusCode != 204) {
        throw const FormatException(
          'Não foi possível redefinir a senha. Tente novamente.',
        );
      }
      await _invalidateSession(expectedSession: session);
    } on DioException catch (error) {
      final response = error.response;
      if (response?.statusCode == 429) {
        _resetRetryAt = _retryAt(response?.headers.value('retry-after'));
        throw RecoveryRateLimit(_resetRetryAt!);
      }
      if (response?.statusCode == 400) {
        final data = response?.data;
        final message = data is Map ? data['mensagem'] : null;
        if (message == 'A nova senha deve ser diferente da atual.') {
          throw const FormatException('Escolha uma senha diferente da atual.');
        }
        if (message == 'Emojis não são permitidos na senha.' ||
            message ==
                'A senha está muito longa. Escolha uma senha mais curta.' ||
            message == 'A nova senha deve ter entre 8 e 72 bytes UTF-8.' ||
            message ==
                'A senha deve ter pelo menos 6 caracteres e não pode conter apenas espaços.') {
          throw FormatException(message as String);
        }
        throw const InvalidRecoveryLink();
      }
      throw const FormatException(
        'Não foi possível redefinir a senha. Tente novamente.',
      );
    }
  }

  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'tv_score_session';
  static int _authAttempt = 0;
  static Future<void>? _sessionStorage;

  static Future<T> _withSessionStorage<T>(Future<T> Function() action) async {
    final previous = _sessionStorage;
    final completed = Completer<void>();
    _sessionStorage = completed.future;
    try {
      if (previous != null) await previous;
      return await action();
    } finally {
      if (identical(_sessionStorage, completed.future)) _sessionStorage = null;
      completed.complete();
    }
  }

  static void _checkAuthAttempt(int attempt) {
    if (attempt != _authAttempt) {
      throw StateError('A sessão mudou. Entre novamente na sua conta.');
    }
  }

  static void _clearAccount() {
    ApiService._token = null;
    ApiService._expiresAt = null;
    ApiService._advanceSession();
    ApiService._clearPrivateState();
    ApiService._sessionRevision.value++;
  }

  Future<void> logout() async {
    _authAttempt++;
    _clearAccount();
    await _withSessionStorage(() => _storage.delete(key: _sessionKey));
  }

  Future<void> _invalidateSession({int? expectedSession}) async {
    if (expectedSession != null &&
        expectedSession != ApiService._sessionVersion) {
      return;
    }
    try {
      await logout();
    } catch (_) {
      // Memory is already cleared. A delayed storage error must not clear a newer login.
      debugPrint('Não foi possível remover a sessão salva.');
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final session = ApiService._sessionVersion;
    final validation = PasswordRecoveryRules.validatePassword(newPassword);
    if (validation != null) throw FormatException(validation);
    if (currentPassword == newPassword) {
      throw const FormatException('Escolha uma senha diferente da atual.');
    }
    try {
      final response = await dio.put(
        '/usuarios/eu/senha',
        data: {'senhaAtual': currentPassword, 'novaSenha': newPassword},
        options: _authorizationOptions,
      );
      ApiService._checkSession(session);
      if (response.statusCode != 204) {
        throw const FormatException(
          'Não foi possível alterar a senha. Tente novamente.',
        );
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _invalidateSession(expectedSession: session);
        rethrow;
      }
      throw FormatException(switch (error.response?.statusCode) {
        400 => 'A nova senha é inválida ou igual à anterior.',
        403 => 'Senha atual incorreta.',
        _ =>
          error.response == null
              ? 'Não foi possível conectar. Verifique sua internet.'
              : 'Não foi possível alterar a senha. Tente novamente.',
      });
    }
    await _invalidateSession(expectedSession: session);
  }

  // Confere a expiração local; a assinatura é validada pelo backend.
  static bool _isUnexpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return false;
      final expiration = payload['exp'];
      return expiration is num &&
          expiration.isFinite &&
          expiration > DateTime.now().millisecondsSinceEpoch / 1000;
    } on FormatException {
      return false;
    }
  }

  Future<void> _loadSessionFavorites() async {
    try {
      await ensureFavoritesLoaded();
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 401) rethrow;
      debugPrint('Favorites could not be loaded; retry on the next access.');
    }
  }

  Future<bool> restoreSession() async {
    final attempt = ++_authAttempt;
    _clearAccount();
    try {
      final value = await _withSessionStorage(
        () => _storage.read(key: _sessionKey),
      );
      _checkAuthAttempt(attempt);
      if (value == null) return false;
      final session = jsonDecode(value);
      if (session is! Map<String, dynamic>) {
        throw const FormatException('Sessão inválida.');
      }
      final token = session['token'];
      final email = session['email'];
      final name = session['name'];
      if (token is! String ||
          !_isUnexpired(token) ||
          email is! String ||
          email.isEmpty ||
          name is! String ||
          name.isEmpty) {
        throw const FormatException('Sessão inválida ou expirada.');
      }
      await open(email, name);
      _checkAuthAttempt(attempt);
      ApiService.token = token;
      try {
        await loadProfilePhoto();
      } on DioException catch (error) {
        if (error.response?.statusCode == 401) rethrow;
        // A temporary connection failure must not discard a valid saved session.
      }
      await _loadSessionFavorites();
      _checkAuthAttempt(attempt);
      return true;
    } catch (_) {
      if (attempt == _authAttempt) {
        await _invalidateSession();
      }
      return false;
    }
  }

  Future<void> loginApi(
    String email,
    String password, {
    bool Function()? isActive,
  }) async {
    final attempt = ++_authAttempt;
    void checkAttempt() {
      _checkAuthAttempt(attempt);
      if (isActive?.call() == false) {
        throw StateError('O login foi cancelado.');
      }
    }

    _clearAccount();
    try {
      await _withSessionStorage(() => _storage.delete(key: _sessionKey));
      checkAttempt();
      final response = await dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'senha': password},
      );
      checkAttempt();
      final dados = response.data as Map<String, dynamic>;
      final tokenRecebido = dados['token'] as String?;
      if (tokenRecebido == null || tokenRecebido.isEmpty) {
        throw const FormatException('Token não recebido do servidor.');
      }
      await open(dados['email'] as String, dados['nome'] as String);
      checkAttempt();
      await _withSessionStorage(() {
        checkAttempt();
        return _storage.write(
          key: _sessionKey,
          value: jsonEncode({
            'token': tokenRecebido,
            'email': ApiService.userEmail,
            'name': ApiService.userName,
          }),
        );
      });
      checkAttempt();
      ApiService.token = tokenRecebido;
      ApiService.userPhotoUrl.value = dados['fotoUrl'] as String?;
      if (!dados.containsKey('fotoUrl')) {
        try {
          await loadProfilePhoto();
        } on DioException catch (error) {
          if (error.response?.statusCode == 401) rethrow;
        }
      }
      await _loadSessionFavorites();
      checkAttempt();
    } on DioException catch (error) {
      debugPrint('Tipo: ${error.type}');
      debugPrint('URL: ${error.requestOptions.uri}');
      debugPrint('Status: ${error.response?.statusCode}');
      if (attempt == _authAttempt) await _invalidateSession();
      final status = error.response?.statusCode;
      throw FormatException(
        status == 401
            ? 'E-mail ou senha incorretos.'
            : error.response == null
            ? 'Não foi possível conectar. Verifique sua internet.'
            : status != null && status >= 500
            ? 'O servidor está indisponível. Tente novamente.'
            : 'Não foi possível entrar. Confira seus dados e tente novamente.',
      );
    } catch (_) {
      if (attempt == _authAttempt) await _invalidateSession();
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    final validation = PasswordRecoveryRules.validatePassword(password);
    if (validation != null) throw FormatException(validation);
    try {
      await dio.post(
        '/auth/cadastrar',
        data: {
          'nome': name.trim(),
          'email': email.trim().toLowerCase(),
          'senha': password,
        },
      );
    } on DioException catch (error) {
      throw FormatException(
        error.response == null
            ? 'Não foi possível conectar. Verifique sua internet.'
            : error.response?.statusCode == 409
            ? 'Este e-mail já está cadastrado.'
            : error.response!.statusCode != null &&
                  error.response!.statusCode! >= 500
            ? 'O servidor está indisponível. Tente novamente.'
            : 'Não foi possível criar a conta. Confira os dados e tente novamente.',
      );
    }
  }
}
