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
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/call_media_session.dart';
import '../providers/call_session_controller.dart';
import '../../../telemedicine/domain/entities/doctor.dart';
import '../../../telemedicine/presentation/providers/telemedicine_providers.dart';
import '../../../telemedicine/presentation/widgets/consultation_dispute_dialog.dart';
import '../../../../core/widgets/call_controls.dart';
import '../../../../core/widgets/call_metrics.dart';

/// Экран звонка: видео или аудио, по `Appointment.kind`.
///
/// Свёрстан по `design/Видео-звонок.png`, `design/Аудио-звонок.png` и
/// парным экранам «завершен» — четыре макета сведены в один экран с двумя
/// состояниями (активный звонок / завершён), а не четыре разных виджета.
///
/// При наличии `consultation_id` экран получает серверный LiveKit-токен,
/// публикует свои дорожки и показывает удалённое видео. До появления дорожки
/// остаются те же фотографии-плейсхолдеры, что были предусмотрены макетом.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  Timer? _ticker;
  CallSessionController? _call;
  String? _callConsultationId;
  Duration _elapsed = Duration.zero;
  var _ended = false;
  var _disputeSubmitting = false;
  var _disputeSubmitted = false;

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
    _call?.removeListener(_onCallChanged);
    _call?.dispose();
    super.dispose();
  }

  void _onCallChanged() {
    if (mounted) setState(() {});
  }

  void _ensureCall(Appointment appointment) {
    final consultationId = appointment.consultationId;
    if (consultationId == null || _callConsultationId == consultationId) {
      return;
    }
    _callConsultationId = consultationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _call != null) return;
      final controller = ref.read(callSessionControllerFactoryProvider)();
      _call = controller..addListener(_onCallChanged);
      unawaited(
        controller.connect(
          consultationId,
          enableVideo: appointment.kind == AppointmentKind.videoCall,
        ),
      );
      setState(() {});
    });
  }

  void _handleHangUp() {
    if (_ended) {
      Navigator.of(context).maybePop();
      return;
    }
    _ticker?.cancel();
    unawaited(_call?.hangUp(completeConsultation: false));
    setState(() => _ended = true);
  }

  Future<void> _openDispute(String consultationId) async {
    final reason = await showConsultationDisputeDialog(context);
    if (reason == null || !mounted) return;

    setState(() => _disputeSubmitting = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(consultationsRepositoryProvider)
          .dispute(consultationId, reason);
      if (!mounted) return;
      setState(() => _disputeSubmitted = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.consultationDisputeSuccess)));
    } catch (_) {
      if (mounted) {
        showFormErrorSnackBar(context, l10n.consultationDisputeError);
      }
    } finally {
      if (mounted) setState(() => _disputeSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = ref.watch(appointmentProvider(widget.appointmentId));
    final doctorId = appointment.value?.doctorId;
    final doctor = doctorId == null
        ? null
        : ref.watch(doctorProvider(doctorId)).value;
    final selfAvatar = ref.watch(profileProvider).value?.avatarAsset;
    final value = appointment.value;
    if (value != null) _ensureCall(value);
    final call = _call?.state ?? const CallSessionState();

    return AppScaffold(
      background: AppBackgroundStyle.call,
      child: SafeArea(
        bottom: false,
        child: value == null || doctor == null
            ? const Center(child: CircularProgressIndicator())
            : _Content(
                kind: value.kind,
                doctor: doctor,
                selfAvatar: selfAvatar,
                consultationId: value.consultationId,
                call: call,
                elapsed: _elapsed,
                ended: _ended || call.status == CallSessionStatus.ended,
                onHangUp: _handleHangUp,
                onToggleCamera: _call?.toggleCamera,
                onToggleMicrophone: _call?.toggleMicrophone,
                disputeSubmitted: _disputeSubmitted,
                disputeSubmitting: _disputeSubmitting,
                onDispute: value.consultationId == null
                    ? null
                    : () => _openDispute(value.consultationId!),
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
    required this.consultationId,
    required this.call,
    required this.elapsed,
    required this.ended,
    required this.onHangUp,
    required this.onToggleCamera,
    required this.onToggleMicrophone,
    required this.disputeSubmitted,
    required this.disputeSubmitting,
    required this.onDispute,
  });

  final AppointmentKind kind;
  final Doctor doctor;
  final String? selfAvatar;
  final String? consultationId;
  final CallSessionState call;
  final Duration elapsed;
  final bool ended;
  final VoidCallback onHangUp;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleMicrophone;
  final bool disputeSubmitted;
  final bool disputeSubmitting;
  final VoidCallback? onDispute;

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
          if (call.errorMessage case final message?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.callDecline,
                ),
              ),
            ),
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
                    consultationId: consultationId,
                    remoteVideo: call.remoteVideo,
                    localVideo: call.localVideo,
                    cameraEnabled: call.status == CallSessionStatus.idle
                        ? null
                        : call.cameraEnabled,
                    microphoneEnabled: call.status == CallSessionStatus.idle
                        ? true
                        : call.microphoneEnabled,
                    onHangUp: onHangUp,
                    onToggleCamera: onToggleCamera,
                    onToggleMicrophone: onToggleMicrophone,
                  )
                : _AudioBody(
                    doctor: doctor,
                    consultationId: consultationId,
                    microphoneEnabled: call.status == CallSessionStatus.idle
                        ? true
                        : call.microphoneEnabled,
                    onHangUp: onHangUp,
                    onToggleMicrophone: onToggleMicrophone,
                  ),
          ),
          if (ended && !disputeSubmitted && onDispute != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: Center(
                child: TextButton(
                  key: const ValueKey('consultation-dispute-action'),
                  onPressed: disputeSubmitting ? null : onDispute,
                  child: disputeSubmitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.consultationDisputeAction),
                ),
              ),
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
    required this.consultationId,
    required this.remoteVideo,
    required this.localVideo,
    required this.cameraEnabled,
    required this.microphoneEnabled,
    required this.onHangUp,
    required this.onToggleCamera,
    required this.onToggleMicrophone,
  });

  final Doctor doctor;
  final String? selfAvatar;
  final String? consultationId;
  final CallVideoFeed? remoteVideo;
  final CallVideoFeed? localVideo;
  final bool? cameraEnabled;
  final bool microphoneEnabled;
  final VoidCallback onHangUp;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleMicrophone;

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
            child: _Photo(
              doctor: doctor,
              radius: AppRadius.allLg,
              video: remoteVideo,
            ),
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
                cameraEnabled: cameraEnabled,
                microphoneEnabled: microphoneEnabled,
                onToggleCamera: onToggleCamera,
                onToggleMicrophone: onToggleMicrophone,
                onHangUp: onHangUp,
                onChat: consultationId == null
                    ? null
                    : () => context.push(Routes.chatOf(consultationId!)),
              ),
              _SelfView(asset: selfAvatar, video: localVideo),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioBody extends StatelessWidget {
  const _AudioBody({
    required this.doctor,
    required this.consultationId,
    required this.microphoneEnabled,
    required this.onHangUp,
    required this.onToggleMicrophone,
  });

  final Doctor doctor;
  final String? consultationId;
  final bool microphoneEnabled;
  final VoidCallback onHangUp;
  final VoidCallback? onToggleMicrophone;

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
          microphoneEnabled: microphoneEnabled,
          onToggleMicrophone: onToggleMicrophone,
          onHangUp: onHangUp,
          onChat: consultationId == null
              ? null
              : () => context.push(Routes.chatOf(consultationId!)),
        ),
      ],
    );
  }
}

/// Фотография врача — тот же плейсхолдер, что и в `DoctorHeader`: фото с
/// бэкенда пока не приходит.
class _Photo extends StatelessWidget {
  const _Photo({required this.doctor, required this.radius, this.video});

  final Doctor doctor;
  final BorderRadius radius;
  final CallVideoFeed? video;

  @override
  Widget build(BuildContext context) {
    final feed = video;
    if (feed != null) {
      return ClipRRect(borderRadius: radius, child: feed.view(mirror: false));
    }
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

/// Самопросмотр (PIP): локальная камера, а до её публикации — аватар из
/// «Ваша Мед-Карта»/«Настроек профиля».
class _SelfView extends StatelessWidget {
  const _SelfView({required this.asset, this.video});

  final String? asset;
  final CallVideoFeed? video;

  @override
  Widget build(BuildContext context) {
    final feed = video;
    if (feed == null) {
      return UserAvatar(
        asset: asset,
        size: CallMetrics.selfViewSize,
        borderRadius: AppRadius.allLg,
      );
    }
    return SizedBox.fromSize(
      size: CallMetrics.selfViewSize,
      child: ClipRRect(
        borderRadius: AppRadius.allLg,
        child: feed.view(mirror: true),
      ),
    );
  }
}
