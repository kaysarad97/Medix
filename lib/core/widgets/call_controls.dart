import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'call_metrics.dart';
import 'icon_chip.dart';

/// Ромб из четырёх круглых кнопок: видеокамера сверху, пауза слева, чат
/// справа, сброс звонка снизу — `design/Видео-звонок.png`.
///
/// На аудио-звонке та же кнопка видеокамеры перечёркнута — камера не
/// включена — и своей позиции у ромба нет, он просто центрирован на
/// экране, без самопросмотра рядом.
///
/// Лежит в `core/`, потому что тот же ромб стоит и на звонке врача. Цвет
/// сброса задаётся снаружи: у пациента он красный, у врача в макете
/// розовый (`#FE569D`).
class CallControls extends StatelessWidget {
  const CallControls({
    super.key,
    required this.isVideo,
    required this.onHangUp,
    this.onChat,
    this.hangUpColor = AppColors.callDecline,
  });

  final bool isVideo;
  final VoidCallback onHangUp;
  final VoidCallback? onChat;
  final Color hangUpColor;

  static const double _radius = CallMetrics.controlSize / 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: CallMetrics.controlsClusterSize,
      child: Stack(
        children: [
          Positioned(
            left: CallMetrics.controlsClusterSize.width / 2 - _radius,
            top: 0,
            child: _ControlButton(
              icon: isVideo ? MedixIcon.videoCall : MedixIcon.videoOff,
            ),
          ),
          const Positioned(
            left: 0,
            top: CallMetrics.controlsSideTop,
            child: _ControlButton(icon: null, isPause: true),
          ),
          Positioned(
            right: 0,
            top: CallMetrics.controlsSideTop,
            child: _ControlButton(icon: MedixIcon.chat, onTap: onChat),
          ),
          Positioned(
            left: CallMetrics.controlsClusterSize.width / 2 - _radius,
            bottom: 0,
            child: _ControlButton(
              icon: MedixIcon.callDecline,
              color: hangUpColor,
              onTap: onHangUp,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    this.color = AppColors.primary,
    this.isPause = false,
    this.onTap,
  });

  final MedixIcon? icon;
  final Color color;
  final bool isPause;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: CallMetrics.controlSize,
      child: Material(
        color: AppColors.surfaceWhite,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: isPause
                ? Icon(Icons.pause, size: 24, color: color)
                : AppIcon(icon: icon!, size: 24, color: color),
          ),
        ),
      ),
    );
  }
}
