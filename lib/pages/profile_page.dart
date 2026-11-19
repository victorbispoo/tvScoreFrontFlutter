import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/widgets/user_avatar.dart';

import '../core/app_breakpoints.dart';
import '../core/app_routes.dart';
import '../core/theme_controller.dart';
import '../services/api_services.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/genre_preferences.dart';
import '../widgets/guest_account_prompt.dart';
import '../widgets/tv_score_segmented_control.dart';
import '../widgets/tv_score_snackbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.isActive = true, this.bottomPadding = 20});

  final bool isActive;
  final double bottomPadding;

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
    _reviewStats = widget.isActive && ApiService.hasSession
        ? _fetchReviewStats()
        : Future.value((count: 0, average: null));
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (ApiService.hasSession && widget.isActive && !oldWidget.isActive) {
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
    useSafeArea: Theme.of(context).brightness == Brightness.dark,
    builder: (_) => const ContentPreferencesDialog(isEditing: true),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              AppBreakpoints.supportsWidePages &&
              constraints.maxWidth >= AppBreakpoints.tablet;
          final inset = wide
              ? ((constraints.maxWidth - 960) / 2).clamp(28.0, double.infinity)
              : 20.0;
          final available = constraints.maxWidth - 2 * inset;
          final twoColumns = wide && available >= 660;
          const gap = 32.0;
          final sectionWidth = twoColumns ? (available - gap) / 2 : available;
          final desktopColumns =
              twoColumns &&
              AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
          final logout = TextButton.icon(
            onPressed: _logout,
            icon: Icon(HugeIconsStroke.logout01),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              minimumSize: const Size(48, 48),
            ),
            label: const Text('Sair da conta'),
          );
          final libraryItems = <Widget>[
            ListTile(
              minVerticalPadding: wide ? 16 : null,
              leading: const Icon(
                HugeIconsStroke.preferenceHorizontal,
                color: Colors.lightBlueAccent,
              ),
              title: const Text('Preferências de conteúdo'),
              subtitle: const Text(
                'Edite seus gêneros, filmes e séries preferidos',
              ),
              trailing: const Icon(HugeIconsStroke.arrowRight01),
              onTap: _editPreferences,
            ),
            ListTile(
              minVerticalPadding: wide ? 16 : null,
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
          ];
          const libraryTitle = Text(
            'Sua biblioteca',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          );
          const personalizationTitle = Text(
            'Personalização',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          );
          final appearance = _ProfileGlassSurface(
            wide: wide,
            child: Padding(
              padding: EdgeInsets.all(wide ? 22 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aparência',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: wide ? 16 : 12),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.instance,
                    builder: (context, mode, _) =>
                        TvScoreSegmentedControl<ThemeMode>(
                          options: const {
                            ThemeMode.light: 'Claro',
                            ThemeMode.dark: 'Escuro',
                            ThemeMode.system: 'Sistema',
                          },
                          selectedValue: mode,
                          onChanged: (next) async {
                            try {
                              await ThemeController.instance.select(next);
                            } catch (_) {
                              if (context.mounted) {
                                TvScoreSnackbar.error(
                                  context,
                                  'Não foi possível salvar a aparência. Tente novamente.',
                                );
                              }
                            }
                          },
                        ),
                  ),
                ],
              ),
            ),
          );
          if (!ApiService.hasSession) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                inset,
                wide ? 32 : 20,
                inset,
                wide ? 24 + widget.bottomPadding : widget.bottomPadding,
              ),
              children: [
                const Text(
                  'Perfil',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: GuestAccountPrompt(
                    icon: HugeIconsStroke.user,
                    title: 'Sua conta no TVScore',
                    message:
                        'Entre ou crie uma conta para organizar seus favoritos e avaliações.',
                  ),
                ),
                personalizationTitle,
                SizedBox(height: wide ? 16 : 12),
                appearance,
              ],
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              inset,
              wide ? 32 : 20,
              inset,
              wide ? 24 + widget.bottomPadding : widget.bottomPadding,
            ),
            children: [
              const Text(
                'Perfil',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: wide ? 28 : 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: ApiService.userPhotoUrl,
                    builder: (_, url, _) => UserAvatar(
                      name: ApiService.userName,
                      imageUrl: url,
                      size: wide ? 116 : 72,
                    ),
                  ),
                  SizedBox(width: wide ? 24 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ApiService.userName,
                          style: TextStyle(
                            fontSize: wide ? 34 : 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ApiService.userEmail,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: wide ? 15 : 13,
                          ),
                        ),
                        SizedBox(height: wide ? 12 : 6),
                        TextButton(
                          onPressed: _editProfile,
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            padding: wide
                                ? const EdgeInsets.symmetric(horizontal: 16)
                                : EdgeInsets.zero,
                            side: wide
                                ? BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  )
                                : null,
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
              SizedBox(height: wide ? 36 : 20),
              const Text(
                'Suas estatísticas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (!wide)
                Divider(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1,
                ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? 780 : double.infinity,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ProfileStat(
                          wide: wide,
                          value: '${ApiService.savedContents.length}',
                          label: 'Favoritos',
                        ),
                      ),
                      SizedBox(width: wide ? 16 : 8),
                      Expanded(
                        child: FutureBuilder<({int count, double? average})>(
                          future: _reviewStats,
                          builder: (context, snapshot) => _ProfileStat(
                            wide: wide,
                            value: snapshot.hasError
                                ? '—'
                                : snapshot.connectionState !=
                                      ConnectionState.done
                                ? '…'
                                : '${snapshot.data?.count ?? 0}',
                            label: 'Avaliações',
                          ),
                        ),
                      ),
                      SizedBox(width: wide ? 16 : 8),
                      Expanded(
                        child: FutureBuilder<({int count, double? average})>(
                          future: _reviewStats,
                          builder: (context, snapshot) => _ProfileStat(
                            wide: wide,
                            value: snapshot.hasError
                                ? '—'
                                : snapshot.connectionState !=
                                      ConnectionState.done
                                ? '…'
                                : snapshot.data?.average?.toStringAsFixed(1) ??
                                      '—',
                            label: 'Média',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (desktopColumns) ...[
                const SizedBox(height: 32),
                Table(
                  columnWidths: const {1: FixedColumnWidth(gap)},
                  children: [
                    const TableRow(
                      children: [
                        libraryTitle,
                        SizedBox.shrink(),
                        personalizationTitle,
                      ],
                    ),
                    const TableRow(
                      children: [
                        SizedBox(height: 16),
                        SizedBox.shrink(),
                        SizedBox.shrink(),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          verticalAlignment:
                              TableCellVerticalAlignment.intrinsicHeight,
                          child: _ProfileGlassSurface(
                            wide: true,
                            child: Column(
                              children: [
                                libraryItems.first,
                                const SizedBox(height: 12),
                                libraryItems.last,
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox.shrink(),
                        TableCell(
                          verticalAlignment:
                              TableCellVerticalAlignment.intrinsicHeight,
                          child: appearance,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(child: logout),
              ] else
                Wrap(
                  spacing: gap,
                  children: [
                    SizedBox(
                      width: sectionWidth.clamp(0.0, double.infinity),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: wide ? 32 : 20),
                          libraryTitle,
                          SizedBox(height: wide ? 16 : 12),
                          for (final item in libraryItems)
                            Padding(
                              padding: EdgeInsets.only(bottom: wide ? 12 : 8),
                              child: _ProfileGlassSurface(
                                wide: wide,
                                child: item,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: sectionWidth.clamp(0.0, double.infinity),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: wide ? 32 : 20),
                          personalizationTitle,
                          SizedBox(height: wide ? 16 : 12),
                          appearance,
                          if (wide) const SizedBox(height: 12),
                          logout,
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    required this.wide,
  });

  final String value;
  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) => _ProfileGlassSurface(
    wide: wide,
    child: Padding(
      padding: EdgeInsets.all(wide ? 22 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: wide ? 40 : 32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: wide ? 14 : 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileGlassSurface extends StatelessWidget {
  const _ProfileGlassSurface({required this.child, required this.wide});

  final Widget child;
  final bool wide;
  static const double radius = 16;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(radius);
    final surface = Material(
      color: wide ? colors.surface : colors.surface.withValues(alpha: .96),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colors.primary.withValues(alpha: .14)),
      ),
      clipBehavior: wide ? Clip.antiAlias : Clip.none,
      child: child,
    );
    if (wide) return surface;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: surface,
      ),
    );
  }
}
