import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_contacts_card.dart';
import '../widgets/doctor_info_card.dart';
import '../widgets/doctor_profile_header.dart';
import '../widgets/doctor_profile_link_row.dart';
import '../widgets/doctor_profile_metrics.dart';

/// «Ваш Профиль» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/Профиль -  в.ф.png`. У
/// фрилансера тот же экран без строки «Запросы в администрацию» —
/// см. [showAdminRequests], макет `design/врач прилансер/Профиль -  в.ф.png`
/// отличается только этим.
///
/// Маршрут зарегистрирован отдельно от реального входа — см.
/// `DoctorHomeScreen` и HANDOFF.md, «Кабинет врача».
///
/// Фото под фото-плашкой — «изменить фото» — тоже вне макета: там фото
/// нарисовано, но без подписи-ссылки. Добавлена по тому же приёму, что и
/// пациентская «изменить аватара» на «Настройках профиля»: без неё
/// presigned-загрузку [doctorMediaRepositoryProvider] было бы не
/// дотянуть до экрана.
class DoctorOwnProfileScreen extends ConsumerStatefulWidget {
  const DoctorOwnProfileScreen({super.key, this.showAdminRequests});

  /// `false` у врача-фрилансера: своей администрации нет.
  /// `null` определяет тип врача по серверному профилю.
  final bool? showAdminRequests;

  @override
  ConsumerState<DoctorOwnProfileScreen> createState() =>
      _DoctorOwnProfileScreenState();
}

class _DoctorOwnProfileScreenState
    extends ConsumerState<DoctorOwnProfileScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _changePhoto() async {
    if (_isUploadingPhoto) return;

    final file = await ref.read(doctorFilePickerProvider).pickPhoto();
    if (file == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
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
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(doctorOwnProfileProvider).value;
    final shouldShowAdminRequests =
        widget.showAdminRequests ?? (profile != null && !profile.isFreelancer);

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
                  title: l10n.doctorOwnProfileTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: GestureDetector(
                    onTap: () => context.push(Routes.doctorSettings),
                    child: const AppIcon(
                      icon: MedixIcon.settings,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DoctorProfileMetrics.topBarToPhoto),
              if (profile != null) ...[
                DoctorProfileHeader(
                  profile: profile,
                  onChangePhoto: _changePhoto,
                  isUploadingPhoto: _isUploadingPhoto,
                ),
                const SizedBox(height: DoctorProfileMetrics.photoToCard),
                _Section(child: DoctorInfoCard(profile: profile)),
                const SizedBox(height: DoctorProfileMetrics.cardGap),
                _Section(
                  child: DoctorContactsCard(
                    phone: profile.phone,
                    email: profile.email,
                  ),
                ),
                const SizedBox(height: DoctorProfileMetrics.cardGap),
                _Section(
                  child: DoctorProfileLinkRow(
                    icon: MedixIcon.medicalCard,
                    title: l10n.doctorCertificatesTitle,
                    onTap: () => context.push(Routes.doctorCertificates),
                  ),
                ),
                const SizedBox(height: DoctorProfileMetrics.linkRowGap),
                _Section(
                  child: DoctorProfileLinkRow(
                    icon: MedixIcon.chat,
                    title: l10n.doctorReviewsAboutYouTitle,
                    onTap: () => context.push(Routes.doctorOwnReviews),
                  ),
                ),
                if (shouldShowAdminRequests) ...[
                  const SizedBox(height: DoctorProfileMetrics.linkRowGap),
                  _Section(
                    child: DoctorProfileLinkRow(
                      icon: MedixIcon.planFamily,
                      title: l10n.doctorAdminRequestsTitle,
                    ),
                  ),
                ],
              ],
              SizedBox(
                height:
                    DoctorProfileMetrics.cardGap +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorProfileMetrics.screenH,
      ),
      child: child,
    );
  }
}
