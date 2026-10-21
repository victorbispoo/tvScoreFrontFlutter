part of 'api_services.dart';

extension AuthService on ApiService {
  void logout() {
  ApiService.token = null;
  ApiService.userName = '';
  ApiService.userEmail = '';
  ApiService.savedMovies = [];
  ApiService.reviews = [];
}
  Future<void> loginApi(String email, String password) async {
    ApiService.token = null;
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'senha': password},
      );
      final dados = response.data as Map<String, dynamic>;
      final tokenRecebido = dados['token'] as String?;
      if (tokenRecebido == null || tokenRecebido.isEmpty) {
        throw const FormatException('Token não recebido do servidor.');
      }
      ApiService.token = tokenRecebido;
      await open(dados['email'] as String, dados['nome'] as String);
    } on DioException catch (error) {
      print('Tipo: ${error.type}');
print('URL: ${error.requestOptions.uri}');
print('Status: ${error.response?.statusCode}');
print('Mensagem: ${error.message}');
      ApiService.token = null;
      final body = error.response?.data;
      throw FormatException(
        body is Map
            ? body['mensagem']?.toString() ?? 'Erro ao efetuar login.'
            : 'Não foi possível conectar ao servidor.',
      );
    } catch (_) {
      ApiService.token = null;
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
