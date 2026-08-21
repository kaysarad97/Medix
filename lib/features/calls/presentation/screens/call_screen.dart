import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/doctor_photo.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../telemedicine/domain/entities/doctor.dart';
import '../../../telemedicine/presentation/providers/telemedicine_providers.dart';
import '../../../../core/widgets/call_controls.dart';
import '../../../../core/widgets/call_metrics.dart';

/// Экран звонка: видео или аудио, по `Appointment.kind`.
///
/// Свёрстан по `design/Видео-звонок.png`, `design/Аудио-звонок.png` и
/// парным экранам «завершен» — четыре макета сведены в один экран с двумя
/// состояниями (активный звонок / завершён), а не четыре разных виджета.
///
/// Технологии звонков ещё нет (см. HANDOFF.md, «решение по технологии» не
/// принято) — таймер идёт локально от нуля, кнопка сброса переводит экран
/// в состояние «Вызов завершен»; реального медиапотока нет ни на одном
/// этапе. Фото врача — та же подложка-плейсхолдер, что и в `DoctorHeader`:
/// `doctor.photoUrl` с бэкенда пока не приходит.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  var _ended = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _handleHangUp() {
    if (_ended) {
      Navigator.of(context).maybePop();
      return;
    }
    _ticker?.cancel();
    setState(() => _ended = true);
  }

  @override
  Widget build(BuildContext context) {
    final appointment = ref.watch(appointmentProvider(widget.appointmentId));
    final doctorId = appointment.value?.doctorId;
    final doctor = doctorId == null
        ? null
        : ref.watch(doctorProvider(doctorId)).value;
    final selfAvatar = ref.watch(profileProvider).value?.avatarAsset;

    return AppScaffold(
      background: AppBackgroundStyle.call,
      child: SafeArea(
        bottom: false,
        child: appointment.value == null || doctor == null
            ? const Center(child: CircularProgressIndicator())
            : _Content(
                kind: appointment.value!.kind,
                doctor: doctor,
                selfAvatar: selfAvatar,
                elapsed: _elapsed,
                ended: _ended,
                onHangUp: _handleHangUp,
              ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.kind,
    required this.doctor,
    required this.selfAvatar,
    required this.elapsed,
    required this.ended,
    required this.onHangUp,
  });

  final AppointmentKind kind;
  final Doctor doctor;
  final String? selfAvatar;
  final Duration elapsed;
  final bool ended;
  final VoidCallback onHangUp;

  bool get _isVideo => kind == AppointmentKind.videoCall;

  String _timerLabel() {
    final minutes = elapsed.inMinutes;
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: CallMetrics.topBarTop),
          ScreenTopBar(
            title: _isVideo ? l10n.videoCallSubtitle : l10n.audioCallLabel,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: CallMetrics.topBarToStatus),
          Center(child: Text(_timerLabel(), style: AppTypography.callStatus)),
          if (ended) ...[
            const SizedBox(height: CallMetrics.statusLines),
            Center(
              child: Text(l10n.callEndedLabel, style: AppTypography.callStatus),
            ),
          ],
          Opacity(
            opacity: ended ? 0.43 : 1,
            child: _isVideo
                ? _VideoBody(
                    doctor: doctor,
                    selfAvatar: selfAvatar,
                    onHangUp: onHangUp,
                  )
                : _AudioBody(doctor: doctor, onHangUp: onHangUp),
          ),
        ],
      ),
    );
  }
}

class _VideoBody extends StatelessWidget {
  const _VideoBody({
    required this.doctor,
    required this.selfAvatar,
    required this.onHangUp,
  });

  final Doctor doctor;
  final String? selfAvatar;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CallMetrics.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: CallMetrics.statusToPhoto),
          SizedBox(
            height: CallMetrics.videoPhotoHeight,
            child: _Photo(doctor: doctor, radius: AppRadius.allLg),
          ),
          const SizedBox(height: CallMetrics.photoToName),
          Text(doctor.fullName, style: AppTypography.titleMd),
          const SizedBox(height: CallMetrics.nameToControls),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CallControls(
                isVideo: true,
                onHangUp: onHangUp,
                onChat: () => context.push(Routes.chatOf('t1')),
              ),
              _SelfView(asset: selfAvatar),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioBody extends StatelessWidget {
  const _AudioBody({required this.doctor, required this.onHangUp});

  final Doctor doctor;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: CallMetrics.statusToAudioPhoto),
        SizedBox(
          width: CallMetrics.audioPhotoSize.width,
          height: CallMetrics.audioPhotoSize.height,
          child: _Photo(doctor: doctor, radius: AppRadius.allLg),
        ),
        const SizedBox(height: CallMetrics.audioPhotoToName),
        Text(doctor.fullName, style: AppTypography.titleMd),
        const SizedBox(height: CallMetrics.audioNameToControls),
        CallControls(
          isVideo: false,
          onHangUp: onHangUp,
          onChat: () => context.push(Routes.chatOf('t1')),
        ),
      ],
    );
  }
}

/// Фотография врача — тот же плейсхолдер, что и в `DoctorHeader`: фото с
/// бэкенда пока не приходит.
class _Photo extends StatelessWidget {
  const _Photo({required this.doctor, required this.radius});

  final Doctor doctor;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.5),
        borderRadius: radius,
      ),
      child: DoctorPhoto(
        seed: doctor.id,
        url: doctor.photoUrl,
        borderRadius: radius,
      ),
    );
  }
}

/// Самопросмотр (PIP) — аватар самого пользователя, тот же выбор, что и на
/// «Ваша Мед-Карта»/«Настройках профиля». Настоящей камеры нет.
class _SelfView extends StatelessWidget {
  const _SelfView({required this.asset});

  final String? asset;

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      asset: asset,
      size: CallMetrics.selfViewSize,
      borderRadius: AppRadius.allLg,
    );
  }
}
