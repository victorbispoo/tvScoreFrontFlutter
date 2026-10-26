part of 'api_services.dart';

extension AuthService on ApiService {
  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'tv_score_session';

  static void _clearAccount() {
    ApiService.token = null;
    ApiService.userName = '';
    ApiService.userEmail = '';
    ApiService.savedMovies = [];
    ApiService.reviews = [];
  }

  Future<void> logout() async {
    await _storage.delete(key: _sessionKey);
    _clearAccount();
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
    } on DioException catch (error) {
      debugPrint('Tipo: ${error.type}');
      debugPrint('URL: ${error.requestOptions.uri}');
      debugPrint('Status: ${error.response?.statusCode}');
      _clearAccount();
      final body = error.response?.data;
      throw FormatException(
        body is Map
            ? body['mensagem']?.toString() ?? 'Erro ao efetuar login.'
            : 'Não foi possível conectar ao servidor.',
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
      final body = error.response?.data;

      throw FormatException(
        body is Map
            ? body['message']?.toString() ?? 'Erro ao registrar usuário.'
            : ' Não foi possível conectar ao servidor.',
      );
    }
  }
}
