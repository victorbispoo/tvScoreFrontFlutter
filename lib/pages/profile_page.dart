import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/widgets/user_avatar.dart';

import '../core/app_routes.dart';
import '../services/api_services.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/genre_preferences.dart';
import '../widgets/tv_score_snackbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  final _api = ApiService();
  late Future<({int count, double? average})> _reviewStats;

  @override
  bool get wantKeepAlive => true;

  Future<({int count, double? average})> _fetchReviewStats() async {
    final reviews = await _api.getMyReviews();
    final total = reviews.fold<double>(
      0,
      (sum, review) => sum + (review['nota'] as num).toDouble(),
    );
    return (
      count: reviews.length,
      average: reviews.isEmpty ? null : total / reviews.length,
    );
  }

  @override
  void initState() {
    super.initState();
    _reviewStats = widget.isActive
        ? _fetchReviewStats()
        : Future.value((count: 0, average: null));
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _reviewStats = _fetchReviewStats();
    }
  }

  Future<void> _logout() async {
    try {
      await _api.logout();
    } catch (_) {
      if (!mounted) return;
      TvScoreSnackbar.error(
        context,
        'Não foi possível sair da conta. Tente novamente.',
      );
      return;
    }
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<void> _editPreferences() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const GenrePreferencesDialog(isEditing: true),
  );

  bool _editingProfile = false;

  Future<void> _editProfile() async {
    if (_editingProfile) return;
    _editingProfile = true;
    var sessionEnded = false;
    try {
      final saved = await showEditProfileSheet(
        context,
        name: ApiService.userName,
        onSave: _api.updateName,
        photoUrl: ApiService.userPhotoUrl,
        onUploadPhoto: (bytes, progress) =>
            _api.uploadProfilePhoto(bytes, onProgress: progress),
        onRemovePhoto: _api.removeProfilePhoto,
        onChangePassword: (current, next) async {
          try {
            await _api.changePassword(current, next);
            sessionEnded = true;
          } on DioException catch (error) {
            if (error.response?.statusCode != 401) rethrow;
            sessionEnded = true;
          }
        },
      );
      if (mounted && sessionEnded) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        return;
      }
      if (mounted && saved == true) {
        setState(() {});
      }
    } finally {
      _editingProfile = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BackdropGroup(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Perfil',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: ApiService.userPhotoUrl,
                builder: (_, url, _) => UserAvatar(
                  name: ApiService.userName,
                  imageUrl: url,
                  size: 72,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ApiService.userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ApiService.userEmail,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _editProfile,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        alignment: Alignment.centerLeft,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      child: const Text('Editar perfil'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Suas estatísticas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProfileStat(
                  value: '${ApiService.savedContents.length}',
                  label: 'Favoritos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FutureBuilder<({int count, double? average})>(
                  future: _reviewStats,
                  builder: (context, snapshot) => _ProfileStat(
                    value: snapshot.hasError
                        ? '—'
                        : snapshot.connectionState != ConnectionState.done
                        ? '…'
                        : '${snapshot.data?.count ?? 0}',
                    label: 'Avaliações',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FutureBuilder<({int count, double? average})>(
                  future: _reviewStats,
                  builder: (context, snapshot) => _ProfileStat(
                    value: snapshot.hasError
                        ? '—'
                        : snapshot.connectionState != ConnectionState.done
                        ? '…'
                        : snapshot.data?.average?.toStringAsFixed(1) ?? '—',
                    label: 'Média',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'Sua biblioteca',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ProfileGlassSurface(
              child: ListTile(
                leading: const Icon(
                  HugeIconsStroke.preferenceHorizontal,
                  color: Colors.lightBlueAccent,
                ),
                title: const Text('Preferências'),
                subtitle: const Text(
                  'Edite seus gêneros, filmes e séries preferidos',
                ),
                trailing: const Icon(HugeIconsStroke.arrowRight01),
                onTap: _editPreferences,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ProfileGlassSurface(
              child: ListTile(
                leading: Icon(
                  HugeIconsStroke.star,
                  color: Colors.amber,
                  size: 24,
                ),
                title: const Text('Minhas avaliações'),
                trailing: const Icon(HugeIconsStroke.arrowRight01),
                onTap: () async {
                  await Navigator.pushNamed(context, AppRoutes.myReviews);
                  if (!mounted) return;
                  setState(() {
                    _reviewStats = _fetchReviewStats();
                  });
                },
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _logout,
            icon: Icon(HugeIconsStroke.logout01),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white60,
              minimumSize: const Size(48, 48),
            ),
            label: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => _ProfileGlassSurface(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    ),
  );
}

class _ProfileGlassSurface extends StatelessWidget {
  const _ProfileGlassSurface({required this.child});

  final Widget child;
  static const double radius = 16;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter.grouped(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Material(
        color: const Color(0xFF14253D).withValues(alpha: .96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: AppTheme.primary.withValues(alpha: .14)),
        ),
        child: child,
      ),
    ),
  );
}
