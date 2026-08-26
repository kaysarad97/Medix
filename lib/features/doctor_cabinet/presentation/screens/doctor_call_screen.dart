import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/call_controls.dart';
import '../../../../core/widgets/call_metrics.dart';
import '../../../../core/widgets/doctor_photo.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import '../../../calls/data/call_media_session.dart';
import '../../../calls/presentation/providers/call_session_controller.dart';
import '../../domain/entities/doctor_patient.dart';
import '../providers/doctor_cabinet_providers.dart';

/// Звонок со стороны врача.
///
/// Свёрстан по `design/для врача от клиники/Видео-звонок.png`,
/// `.../Аудио-звонок.png` и парным «завершен» (все 440×978). Зеркало
/// пациентского `CallScreen`: крупно пациент, в углу врач.
///
/// Отличий от пациентского экрана три, и все из макета: фото пациента
/// выше (538 против 491), имя подписано поверх фото, а не под ним, и
/// кнопка сброса розовая, а не красная. Ромб кнопок и размеры общие —
/// `CallControls` и `CallMetrics` в `core/widgets`.
///
/// При наличии `consultation_id` экран входит в LiveKit-комнату, показывает
/// удалённую камеру пациента и публикует дорожки врача. Сброс закрывает комнату
/// и завершает консультацию на сервере.
class DoctorCallScreen extends ConsumerStatefulWidget {
  const DoctorCallScreen({super.key, required this.patientId});

  final String patientId;

  /// Розовая кнопка сброса — замер по макету врача, у пациента там
  /// красный `AppColors.callDecline`.
  static const Color hangUpColor = Color(0xFFFE569D);

  /// Фото пациента на видео-звонке: 211…748 по макету.
  static const double videoPhotoHeight = 538;

  /// Аватар пациента внутри большой карточки видео-звонка.
  static const Size videoAvatarSize = Size(220, 260);

  /// Имя поверх фото: краска начинается на 12 от левого края карточки.
  static const EdgeInsets namePadding = EdgeInsets.fromLTRB(16, 14, 16, 0);

  @override
  ConsumerState<DoctorCallScreen> createState() => _DoctorCallScreenState();
}

class _DoctorCallScreenState extends ConsumerState<DoctorCallScreen> {
  Timer? _ticker;
  CallSessionController? _call;
  String? _callConsultationId;
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
    _call?.removeListener(_onCallChanged);
    _call?.dispose();
    super.dispose();
  }

  void _onCallChanged() {
    if (mounted) setState(() {});
  }

  void _ensureCall(DoctorPatient patient) {
    final appointment = patient.appointment;
    final consultationId = appointment?.consultationId;
    if (appointment == null ||
        consultationId == null ||
        _callConsultationId == consultationId) {
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
    unawaited(_call?.hangUp(completeConsultation: true));
    setState(() => _ended = true);
  }

  @override
  Widget build(BuildContext context) {
    final patient = ref.watch(doctorPatientProvider(widget.patientId)).value;
    if (patient != null) _ensureCall(patient);
    final call = _call?.state ?? const CallSessionState();

    return AppScaffold(
      background: AppBackgroundStyle.call,
      child: SafeArea(
        bottom: false,
        child: patient == null
            ? const Center(child: CircularProgressIndicator())
            : _Content(
                patient: patient,
                kind: patient.appointment?.kind ?? AppointmentKind.videoCall,
                consultationId: patient.appointment?.consultationId,
                call: call,
                elapsed: _elapsed,
                ended: _ended || call.status == CallSessionStatus.ended,
                onHangUp: _handleHangUp,
                onToggleCamera: _call?.toggleCamera,
                onToggleMicrophone: _call?.toggleMicrophone,
              ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.patient,
    required this.kind,
    required this.consultationId,
    required this.call,
    required this.elapsed,
    required this.ended,
    required this.onHangUp,
    required this.onToggleCamera,
    required this.onToggleMicrophone,
  });

  final DoctorPatient patient;
  final AppointmentKind kind;
  final String? consultationId;
  final CallSessionState call;
  final Duration elapsed;
  final bool ended;
  final VoidCallback onHangUp;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleMicrophone;

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
                  color: DoctorCallScreen.hangUpColor,
                ),
              ),
            ),
          if (ended) ...[
            const SizedBox(height: CallMetrics.statusLines),
            Center(
              child: Text(l10n.callEndedLabel, style: AppTypography.callStatus),
            ),
          ],
          // Завершённый звонок гасится целиком, как и у пациента.
          Opacity(
            opacity: ended ? 0.43 : 1,
            child: _isVideo
                ? _VideoBody(
                    patient: patient,
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
                    patient: patient,
                    consultationId: consultationId,
                    microphoneEnabled: call.status == CallSessionStatus.idle
                        ? true
                        : call.microphoneEnabled,
                    onHangUp: onHangUp,
                    onToggleMicrophone: onToggleMicrophone,
                  ),
          ),
        ],
      ),
    );
  }
}

class _VideoBody extends StatelessWidget {
  const _VideoBody({
    required this.patient,
    required this.consultationId,
    required this.remoteVideo,
    required this.localVideo,
    required this.cameraEnabled,
    required this.microphoneEnabled,
    required this.onHangUp,
    required this.onToggleCamera,
    required this.onToggleMicrophone,
  });

  final DoctorPatient patient;
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
            height: DoctorCallScreen.videoPhotoHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _PatientPhoto(
                    patient: patient,
                    avatarSize: DoctorCallScreen.videoAvatarSize,
                    video: remoteVideo,
                  ),
                ),
                // Имя в макете подписано поверх фото, а не под ним, как у
                // пациента: на видео врач и так знает, кого позвал, а
                // подпись нужна для полноты кадра.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Padding(
                    padding: DoctorCallScreen.namePadding,
                    child: Text(
                      patient.fullName,
                      style: AppTypography.titleMd.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                hangUpColor: DoctorCallScreen.hangUpColor,
                onChat: consultationId == null
                    ? null
                    : () => context.push(
                        Routes.doctorPatientChatOf(consultationId!),
                      ),
              ),
              _SelfView(patient: patient, video: localVideo),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioBody extends StatelessWidget {
  const _AudioBody({
    required this.patient,
    required this.consultationId,
    required this.microphoneEnabled,
    required this.onHangUp,
    required this.onToggleMicrophone,
  });

  final DoctorPatient patient;
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
          child: _PatientPhoto(patient: patient),
        ),
        const SizedBox(height: CallMetrics.audioPhotoToName),
        Text(patient.fullName, style: AppTypography.titleMd),
        const SizedBox(height: CallMetrics.audioNameToControls),
        CallControls(
          isVideo: false,
          microphoneEnabled: microphoneEnabled,
          onToggleMicrophone: onToggleMicrophone,
          onHangUp: onHangUp,
          hangUpColor: DoctorCallScreen.hangUpColor,
          onChat: consultationId == null
              ? null
              : () => context.push(Routes.doctorPatientChatOf(consultationId!)),
        ),
      ],
    );
  }
}

/// Пациент крупным планом. Пока удалённой дорожки нет, на её месте остаётся
/// аватар из календаря и «Профиля пациента».
///
/// На видео-звонке аватар не растягивается на всю карточку: он рисованный,
/// и в 538 точек высотой превращается в гигантскую голову. Вместо этого
/// стоит по центру подложки — читается как «сигнала нет, вот с кем говорим».
class _PatientPhoto extends StatelessWidget {
  const _PatientPhoto({required this.patient, this.avatarSize, this.video});

  final DoctorPatient patient;

  /// `null` — аватар занимает всю карточку (аудио-звонок, там она сама
  /// размером с аватар).
  final Size? avatarSize;
  final CallVideoFeed? video;

  @override
  Widget build(BuildContext context) {
    final feed = video;
    if (feed != null) {
      return ClipRRect(
        borderRadius: AppRadius.allLg,
        child: feed.view(mirror: false),
      );
    }
    final avatar = UserAvatar(
      asset: patient.avatarAsset,
      size: avatarSize ?? Size.infinite,
      borderRadius: AppRadius.allLg,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.5),
        borderRadius: AppRadius.allLg,
      ),
      child: avatarSize == null ? avatar : Center(child: avatar),
    );
  }
}

/// Самопросмотр врача — портрет из набора дизайнера, как и везде, где
/// фотографии с сервера ещё нет.
class _SelfView extends StatelessWidget {
  const _SelfView({required this.patient, this.video});

  final DoctorPatient patient;
  final CallVideoFeed? video;

  @override
  Widget build(BuildContext context) {
    final feed = video;
    if (feed == null) {
      return SizedBox.fromSize(
        size: CallMetrics.selfViewSize,
        child: DoctorPhoto(seed: patient.id, borderRadius: AppRadius.allLg),
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
