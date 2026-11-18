import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_contents.dart';
import '../models/content_metadata.dart';
import '../models/recommendations.dart';
import '../models/review.dart';

part 'auth_service.dart';
part 'content_service.dart';
part 'favorites_service.dart';
part 'reviews_service.dart';
part 'preferences_service.dart';
part 'recommendations_service.dart';

class ApiService {
  ApiService({DateTime Function()? recommendationClock})
    : _recommendationClock = recommendationClock ?? DateTime.now;

  final DateTime Function() _recommendationClock;
  static final _recommendations = <String, _RecommendationEntry>{};

  static void _invalidateRecommendations(int session) {
    if (session == _sessionVersion) _recommendations.clear();
  }

  static void _advanceSession() {
    _sessionVersion++;
    _recommendations.clear();
  }

  static const maxSearchPage = 500;
  // Use --dart-define=USE_MOCK_MOVIES=false para voltar ao backend.
  static const useMockContents = bool.fromEnvironment(
    'USE_MOCK_MOVIES',
    defaultValue: false,
  );
  final Dio dio = Dio(
    BaseOptions(baseUrl: 'https://tvscore-backend.onrender.com/api'),
  );

  Options get _authorizationOptions =>
      Options(headers: {'Authorization': 'Bearer ${ApiService.token}'});

  static String? _token;
  static String? get token => _token;
  static set token(String? value) {
    if (_token == value) return;
    _token = value;
    _advanceSession();
  }

  static int _sessionVersion = 0;

  static void _checkSession(int version) {
    if (version != _sessionVersion) {
      throw StateError('A sessão mudou. Entre novamente na sua conta.');
    }
  }

  static String userName = '';
  static final userPhotoUrl = ValueNotifier<String?>(null);
  static final contentPreferencesRevision = ValueNotifier<int>(0);
  static String userEmail = '';
  static List<Map<String, String>> savedContents = [];
  static List<Review> reviews = [];
  static Future<List<Map<String, dynamic>>>? _myReviewsRequest;
  static DateTime? _myReviewsFetchedAt;
  static String? _myReviewsToken;
  static final Map<int, (DateTime, Future<Map<String, dynamic>>)>
  _episodePanels = {};

  static void _clearReviewCache() {
    _myReviewsRequest = null;
    _myReviewsFetchedAt = null;
    _myReviewsToken = null;
  }

  Future<void> open(String email, String defaultName) async {
    _advanceSession();
    userPhotoUrl.value = null;
    _clearReviewCache();
    final preferences = SharedPreferencesAsync();
    final value = await preferences.getString('tv_score_library_$email');
    final data = value == null
        ? <String, dynamic>{}
        : jsonDecode(value) as Map<String, dynamic>;

    if (data.containsKey('saved') || data.containsKey('reviews')) {
      data.remove('saved');
      data.remove('reviews');
      await preferences.setString('tv_score_library_$email', jsonEncode(data));
    }

    userEmail = email;
    userName = data['name'] ?? defaultName;
    savedContents = [];
    reviews = [];
  }

  static String profilePhotoMimeType(Uint8List bytes) {
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Escolha uma imagem de até 5 MiB.');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71 &&
        bytes[4] == 13 &&
        bytes[5] == 10 &&
        bytes[6] == 26 &&
        bytes[7] == 10) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'image/jpeg';
    }
    throw const FormatException('Escolha uma imagem JPEG ou PNG.');
  }

  Future<void> loadProfilePhoto() async {
    final session = _sessionVersion;
    final response = await dio.get(
      '/usuarios/eu',
      options: _authorizationOptions,
    );
    _checkSession(session);
    userPhotoUrl.value =
        (response.data as Map<String, dynamic>)['fotoUrl'] as String?;
  }

  Future<void> uploadProfilePhoto(
    Uint8List bytes, {
    ProgressCallback? onProgress,
  }) async {
    final mime = profilePhotoMimeType(bytes);
    final session = _sessionVersion;
    try {
      final response = await dio.put(
        '/usuarios/eu/foto',
        data: FormData.fromMap({
          'arquivo': MultipartFile.fromBytes(
            bytes,
            filename: mime == 'image/png' ? 'perfil.png' : 'perfil.jpg',
            contentType: DioMediaType.parse(mime),
          ),
        }),
        options: _authorizationOptions,
        onSendProgress: onProgress,
      );
      _checkSession(session);
      final url = (response.data as Map<String, dynamic>)['fotoUrl'];
      if (response.statusCode != 200 || url is! String || url.isEmpty) {
        throw const FormatException('Resposta inválida ao atualizar a foto.');
      }
      userPhotoUrl.value = url;
    } on DioException catch (error) {
      throw FormatException(_photoError(error));
    }
  }

  Future<void> removeProfilePhoto() async {
    final session = _sessionVersion;
    try {
      final response = await dio.delete(
        '/usuarios/eu/foto',
        options: _authorizationOptions,
      );
      _checkSession(session);
      if (response.statusCode != 204) {
        throw const FormatException('Não foi possível remover a foto.');
      }
      userPhotoUrl.value = null;
    } on DioException catch (error) {
      throw FormatException(_photoError(error));
    }
  }

  static String _photoError(DioException error) =>
      switch (error.response?.statusCode) {
        400 => 'A imagem é inválida. Escolha outra foto.',
        413 => 'Escolha uma imagem de até 5 MiB.',
        415 => 'Escolha uma imagem JPEG ou PNG.',
        503 => 'O armazenamento está indisponível. Tente novamente mais tarde.',
        401 => 'Sua sessão expirou. Entre novamente na sua conta.',
        _ => 'Não foi possível atualizar a foto. Tente novamente.',
      };

  Future<void> updateName(String name) async {
    final nomeTrim = name.trim();

    if (nomeTrim.isEmpty || nomeTrim.length > 60) {
      throw ArgumentError('Informe um nome de até 60 caracteres.');
    }
    final session = _sessionVersion;
    final email = userEmail;
    if (token == null || token!.isEmpty) {
      throw StateError('Entre na sua conta para editar o perfil.');
    }
    final response = await dio.put(
      '/usuarios/eu',
      data: {'nome': nomeTrim},
      options: _authorizationOptions,
    );
    _checkSession(session);
    final savedName = (response.data as Map)['nome'] as String;
    if (savedName.trim().isEmpty) {
      throw const FormatException('Nome ausente na resposta.');
    }

    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      'tv_score_library_$email',
      jsonEncode({'name': savedName}),
    );
    _checkSession(session);
    userName = savedName;
  }
}
