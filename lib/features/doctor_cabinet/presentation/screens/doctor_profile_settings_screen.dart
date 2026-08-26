import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_own_profile.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_profile_metrics.dart';

/// «Настройки профиля» — только у врача-фрилансера.
///
/// Свёрстан по `design/врач фрилансер/Настройки Профиля.png`. Вход —
/// строка «Настройки профиля» на [DoctorSettingsScreen] (см.
/// `showFreelancerRows`); у врача от клиники этого пункта в макете нет —
/// свои данные ему правит администрация клиники, не он сам.
///
/// Поле «Пароль» — как и на пациентских «Настройках профиля»: в MedIx
/// паролей нет вообще, вход по одноразовому коду. Поле оставлено ради
/// формы макета, но не сохраняется — то же решение, что уже принято для
/// пациентского экрана, просто перенесённое на врача.
class DoctorProfileSettingsScreen extends ConsumerStatefulWidget {
  const DoctorProfileSettingsScreen({super.key});

  @override
  ConsumerState<DoctorProfileSettingsScreen> createState() =>
      _DoctorProfileSettingsScreenState();
}

class _DoctorProfileSettingsScreenState
    extends ConsumerState<DoctorProfileSettingsScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _prefilled = false;
  var _saving = false;
  var _uploadingPhoto = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    if (_uploadingPhoto) return;

    final file = await ref.read(doctorFilePickerProvider).pickPhoto();
    if (file == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(doctorMediaRepositoryProvider)
          .uploadPhoto(
            filename: file.name,
            contentType: file.contentType,
            bytes: file.bytes,
          );
      if (!mounted) return;
      ref.invalidate(doctorOwnProfileProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.doctorPhotoUploadSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.doctorPhotoUploadError)),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  /// Сохраняет и закрывает по стрелке назад — как и у пациентского аналога,
  /// в макете нет ни кнопки «Сохранить», ни галочки в шапке.
  Future<void> _close() async {
    if (_saving) return;

    final profile = ref.read(doctorOwnProfileProvider).value;
    final fullName = [
      _first.text.trim(),
      _last.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    if (profile == null || fullName == profile.fullName) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(doctorCabinetRepositoryProvider)
          .updateOwnProfile(
            DoctorOwnProfile(
              fullName: fullName,
              doctorId: profile.doctorId,
              status: profile.status,
              rating: profile.rating,
              specialization: profile.specialization,
              experience: profile.experience,
              category: profile.category,
              address: profile.address,
              onlineConsultations: profile.onlineConsultations,
              phone: profile.phone,
              email: profile.email,
              isFreelancer: profile.isFreelancer,
              photoUrl: profile.photoUrl,
            ),
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      return;
    }

    ref.invalidate(doctorOwnProfileProvider);
    if (!mounted) return;
    if (!await Navigator.of(context).maybePop() && mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(doctorOwnProfileProvider).value;
    if (profile != null && !_prefilled) {
      _prefilled = true;
      final parts = profile.fullName.split(' ');
      _first.text = parts.isNotEmpty ? parts.first : '';
      _last.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _email.text = profile.email;
    }
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorProfileMetrics.topBarToPhoto),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DoctorProfileMetrics.screenH,
                ),
                child: ScreenTopBar(
                  title: l10n.profileSettingsTitle,
                  onBack: () => _close(),
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _changePhoto,
                child: Center(
                  child: _Photo(
                    isUploading: _uploadingPhoto,
                    photoUrl: profile?.photoUrl,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _changePhoto,
                child: Text(
                  l10n.doctorChangePhotoAction,
                  textAlign: TextAlign.center,
                  style: AppTypography.captionMuted,
                ),
              ),
              const SizedBox(height: DoctorProfileMetrics.photoToCard),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DoctorProfileMetrics.screenH,
                ),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Field(
                        controller: _first,
                        hint: l10n.firstNameHint,
                        enabled: !_saving,
                      ),
                      const SizedBox(height: DoctorProfileMetrics.fieldGap),
                      _Field(
                        controller: _last,
                        hint: l10n.lastNameHint,
                        enabled: !_saving,
                      ),
                      const SizedBox(height: DoctorProfileMetrics.fieldGap),
                      _Field(
                        controller: _email,
                        hint: 'E-mail',
                        enabled: !_saving,
                      ),
                      const SizedBox(height: DoctorProfileMetrics.fieldGap),
                      _Field(
                        controller: _password,
                        hint: l10n.passwordHint,
                        obscure: true,
                        enabled: !_saving,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.isUploading, this.photoUrl});

  final bool isUploading;
  final String? photoUrl;

  static const double _size = 130;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.accentSoft,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null)
              ClipOval(
                child: Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            if (isUploading)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.enabled = true,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorProfileMetrics.fieldHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allPill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            child: TextField(
              controller: controller,
              enabled: enabled,
              obscureText: obscure,
              style: AppTypography.bodyMd,
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTypography.placeholder.copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
