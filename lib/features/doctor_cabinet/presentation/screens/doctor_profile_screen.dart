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
class DoctorOwnProfileScreen extends ConsumerWidget {
  const DoctorOwnProfileScreen({super.key, this.showAdminRequests = true});

  /// `false` у врача-фрилансера: своей администрации нет.
  final bool showAdminRequests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(doctorOwnProfileProvider).value;

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
                  trailing: const AppIcon(
                    icon: MedixIcon.settings,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(height: DoctorProfileMetrics.topBarToPhoto),
              if (profile != null) ...[
                DoctorProfileHeader(profile: profile),
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
                if (showAdminRequests) ...[
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
