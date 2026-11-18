part of 'api_services.dart';

class RecoveryRateLimit implements Exception {
  const RecoveryRateLimit(this.retryAt);
  final DateTime retryAt;
}

extension AuthService on ApiService {
  static DateTime? _recoveryRetryAt;
  static bool _requestingRecovery = false;

  DateTime? get recoveryRetryAt => _recoveryRetryAt;

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
      final data = response.data;
      final message = data is String
          ? data
          : data is Map
          ? data['mensagem'] ?? data['message']
          : null;
      return message is String && message.isNotEmpty
          ? message
          : 'Se houver uma conta com este e-mail, você receberá instruções para recuperar a senha.';
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
    final bytes = utf8.encode(newPassword).length;
    if (token.isEmpty || bytes < 8 || bytes > 72) {
      throw const FormatException(
        'Link inválido ou senha fora do limite de 8 a 72 bytes UTF-8.',
      );
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
    } on DioException catch (error) {
      throw FormatException(
        error.response?.statusCode == 400
            ? 'O link é inválido, expirou ou já foi usado, ou a nova senha é inválida. Solicite outro link ou confira a senha.'
            : 'Não foi possível redefinir a senha. Tente novamente.',
      );
    }
  }

  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'tv_score_session';

  static void _clearAccount() {
    ApiService._advanceSession();
    ApiService._clearReviewCache();
    ApiService._token = null;
    ApiService.userName = '';
    ApiService.userPhotoUrl.value = null;
    ApiService.userEmail = '';
    ApiService.savedContents = [];
    ApiService.reviews = [];
  }

  Future<void> logout() async {
    await _storage.delete(key: _sessionKey);
    _clearAccount();
  }

  Future<void> _invalidateSession() async {
    try {
      await logout();
    } catch (_) {
      _clearAccount();
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final bytes = utf8.encode(newPassword).length;
    if (bytes < 8 || bytes > 72 || currentPassword == newPassword) {
      throw const FormatException(
        'Use uma nova senha diferente, entre 8 e 72 bytes UTF-8.',
      );
    }
    try {
      final response = await dio.put(
        '/usuarios/eu/senha',
        data: {'senhaAtual': currentPassword, 'novaSenha': newPassword},
        options: _authorizationOptions,
      );
      if (response.statusCode != 204) {
        throw const FormatException(
          'Não foi possível alterar a senha. Tente novamente.',
        );
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _invalidateSession();
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
    try {
      await logout();
    } catch (_) {
      // The server has already revoked this session, even if local deletion fails.
      _clearAccount();
    }
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

  Future<bool> restoreSession() async {
    _clearAccount();
    try {
      final value = await _storage.read(key: _sessionKey);
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
      ApiService.token = token;
      try {
        await loadProfilePhoto();
      } on DioException catch (error) {
        if (error.response?.statusCode == 401) rethrow;
        // A temporary connection failure must not discard a valid saved session.
      }
      return true;
    } catch (_) {
      _clearAccount();
      try {
        await _storage.delete(key: _sessionKey);
      } catch (_) {
        debugPrint('Não foi possível remover a sessão salva.');
      }
      return false;
    }
  }

  Future<void> loginApi(String email, String password) async {
    try {
      await logout();
      final response = await dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'senha': password},
      );
      final dados = response.data as Map<String, dynamic>;
      final tokenRecebido = dados['token'] as String?;
      if (tokenRecebido == null || tokenRecebido.isEmpty) {
        throw const FormatException('Token não recebido do servidor.');
      }
      await open(dados['email'] as String, dados['nome'] as String);
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode({
          'token': tokenRecebido,
          'email': ApiService.userEmail,
          'name': ApiService.userName,
        }),
      );
      ApiService.token = tokenRecebido;
      ApiService.userPhotoUrl.value = dados['fotoUrl'] as String?;
      if (!dados.containsKey('fotoUrl')) {
        try {
          await loadProfilePhoto();
        } on DioException catch (error) {
          if (error.response?.statusCode == 401) rethrow;
        }
      }
    } on DioException catch (error) {
      debugPrint('Tipo: ${error.type}');
      debugPrint('URL: ${error.requestOptions.uri}');
      debugPrint('Status: ${error.response?.statusCode}');
      _clearAccount();
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
      _clearAccount();
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
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
