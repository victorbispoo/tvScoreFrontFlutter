import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_theme.dart';
import 'change_password_form.dart';
import 'profile_photo_editor.dart';
import 'user_avatar.dart';

Future<bool?> showEditProfileSheet(
  BuildContext context, {
  required String name,
  required Future<void> Function(String) onSave,
  Future<void> Function(String, String)? onChangePassword,
  ValueListenable<String?>? photoUrl,
  Future<void> Function(Uint8List, void Function(int, int))? onUploadPhoto,
  Future<void> Function()? onRemovePhoto,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  shape: const RoundedRectangleBorder(),
  clipBehavior: Clip.none,
  // All dismissal gestures go through the editor's discard confirmation.
  isDismissible: false,
  enableDrag: false,
  constraints: const BoxConstraints(maxWidth: double.infinity),
  builder: (_) => _EditProfileSheet(
    name: name,
    onSave: onSave,
    onChangePassword: onChangePassword,
    photoUrl: photoUrl,
    onUploadPhoto: onUploadPhoto,
    onRemovePhoto: onRemovePhoto,
  ),
);

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.name,
    required this.onSave,
    this.onChangePassword,
    this.photoUrl,
    this.onUploadPhoto,
    this.onRemovePhoto,
  });
  final String name;
  final Future<void> Function(String) onSave;
  final Future<void> Function(String, String)? onChangePassword;
  final ValueListenable<String?>? photoUrl;
  final Future<void> Function(Uint8List, void Function(int, int))?
  onUploadPhoto;
  final Future<void> Function()? onRemovePhoto;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _name = TextEditingController(text: widget.name);
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  bool _photoPending = false;
  bool _changingPassword = false;
  bool _confirming = false;
  bool _allowClose = false;
  String? _error;
  double _dragDistance = 0;

  bool get _dirty => _photoPending || _name.text.trim() != widget.name.trim();
  bool get _valid =>
      _name.text.trim().isNotEmpty && _name.text.trim().length <= 60;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _finish(bool saved) {
    setState(() => _allowClose = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, saved);
    });
  }

  Future<void> _requestClose() async {
    if (_saving || _confirming || _allowClose) return;
    if (await _confirmDiscard() && mounted) _finish(false);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _changingPassword) return true;
    _confirming = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: Text(
          _photoPending
              ? 'A foto selecionada ainda não foi enviada. Descartar as alterações?'
              : 'As mudanças no nome ainda não foram salvas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    _confirming = false;
    return mounted && discard == true;
  }

  Future<void> _openPassword() async {
    if (_saving || _confirming || _changingPassword) return;
    if (await _confirmDiscard() && mounted) {
      setState(() {
        _name.text = widget.name;
        _changingPassword = true;
        _photoPending = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving ||
        _photoPending ||
        !_dirty ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_name.text.trim());
      if (mounted) _finish(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não foi possível salvar o perfil. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: _allowClose,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _requestClose();
    },
    child: SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('profile-editor-barrier'),
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _requestClose,
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    maxHeight: constraints.maxHeight * .9,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .16),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: .95),
                          shape: RoundedRectangleBorder(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            side: BorderSide(
                              color: const Color(
                                0xFF75ADFF,
                              ).withValues(alpha: .12),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onVerticalDragStart: (_) => _dragDistance = 0,
                                  onVerticalDragUpdate: (details) =>
                                      _dragDistance += details.delta.dy,
                                  onVerticalDragEnd: (details) {
                                    if (_dragDistance > 60 ||
                                        (details.primaryVelocity ?? 0) > 200) {
                                      _requestClose();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      12,
                                      12,
                                      0,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _changingPassword
                                                    ? 'Alterar senha'
                                                    : 'Editar perfil',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip:
                                                  'Fechar edição de perfil',
                                              onPressed: _saving
                                                  ? null
                                                  : _requestClose,
                                              icon: const Icon(
                                                HugeIconsStroke.cancel01,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      8,
                                      20,
                                      24,
                                    ),
                                    child: _changingPassword
                                        ? ChangePasswordForm(
                                            onSubmit: widget.onChangePassword!,
                                            onBusy: (busy) =>
                                                setState(() => _saving = busy),
                                            onSuccess: () => _finish(false),
                                          )
                                        : Form(
                                            key: _form,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Informações da sua conta',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Center(
                                                  child:
                                                      widget.photoUrl != null &&
                                                          widget.onUploadPhoto !=
                                                              null &&
                                                          widget.onRemovePhoto !=
                                                              null
                                                      ? ProfilePhotoEditor(
                                                          name: _name.text,
                                                          photoUrl:
                                                              widget.photoUrl!,
                                                          onUpload: widget
                                                              .onUploadPhoto!,
                                                          onRemove: widget
                                                              .onRemovePhoto!,
                                                          enabled: !_saving,
                                                          onBusy: (busy) =>
                                                              setState(
                                                                () => _saving =
                                                                    busy,
                                                              ),
                                                          onPendingChanged:
                                                              (
                                                                pending,
                                                              ) => setState(
                                                                () =>
                                                                    _photoPending =
                                                                        pending,
                                                              ),
                                                        )
                                                      : UserAvatar(
                                                          name: _name.text,
                                                          size: 120,
                                                        ),
                                                ),
                                                const SizedBox(height: 24),
                                                const Text(
                                                  'Dados pessoais',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Nome',
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_name.text.characters.length}/60',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                TextFormField(
                                                  controller: _name,
                                                  enabled: !_saving,
                                                  maxLength: 60,
                                                  textCapitalization:
                                                      TextCapitalization.words,
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                  validator: (value) =>
                                                      value == null ||
                                                          value.trim().isEmpty
                                                      ? 'Informe seu nome.'
                                                      : value.trim().length > 60
                                                      ? 'Use até 60 caracteres.'
                                                      : null,
                                                  onChanged: (_) => setState(
                                                    () => _error = null,
                                                  ),
                                                  buildCounter:
                                                      (
                                                        _, {
                                                        required currentLength,
                                                        required isFocused,
                                                        required maxLength,
                                                      }) => null,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Como você quer ser chamado?',
                                                    filled: true,
                                                    fillColor: Colors.white
                                                        .withValues(alpha: .04),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha: .1,
                                                                    ),
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppTheme
                                                                    .primary,
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                const Text(
                                                  'Segurança',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                InkWell(
                                                  onTap:
                                                      _saving ||
                                                          widget.onChangePassword ==
                                                              null
                                                      ? null
                                                      : _openPassword,
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  child: Ink(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF1A304F,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: .18,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          HugeIconsStroke
                                                              .lockPassword,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                          size: 22,
                                                        ),
                                                        SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'Alterar senha',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 4,
                                                              ),
                                                              Text(
                                                                'Atualize sua senha com segurança',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Icon(
                                                          HugeIconsStroke
                                                              .arrowRight01,
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (_error != null) ...[
                                                  const SizedBox(height: 16),
                                                  Semantics(
                                                    liveRegion: true,
                                                    child: Text(
                                                      _error!,
                                                      style: TextStyle(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.error,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 24),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: FilledButton.icon(
                                                    onPressed:
                                                        _saving ||
                                                            _photoPending ||
                                                            !_dirty ||
                                                            !_valid
                                                        ? null
                                                        : _save,
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      foregroundColor:
                                                          Colors.white,
                                                      minimumSize: const Size(
                                                        48,
                                                        48,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    icon: _saving
                                                        ? const SizedBox.square(
                                                            dimension: 16,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          )
                                                        : const Icon(
                                                            HugeIconsStroke
                                                                .tick02,
                                                            size: 18,
                                                          ),
                                                    label: Text(
                                                      _saving
                                                          ? 'Salvando...'
                                                          : 'Salvar alterações',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
