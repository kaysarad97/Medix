import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_schedule.dart';
import '../providers/telemedicine_providers.dart';

/// Лист ожидания свободного слота врача.
///
/// Макета под функцию нет. Экран намеренно использует стандартные карточки,
/// типографику и CTA приложения. Навигация после принятия слота передаётся
/// callback-ом, чтобы экран не зависел от общего router во время параллельной
/// работы над ним.
class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key, this.onAppointmentClaimed});

  final ValueChanged<Appointment>? onAppointmentClaimed;

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  String? busyEntryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = ref.watch(waitlistEntriesProvider);

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 36),
            ScreenTopBar(
              title: l10n.waitlistTitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: entries.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: IconButton(
                    tooltip: l10n.waitlistActionError,
                    onPressed: () => ref.invalidate(waitlistEntriesProvider),
                    icon: const Icon(Icons.refresh),
                    color: AppColors.primaryBright,
                  ),
                ),
                data: (items) {
                  final visible = items
                      .where(
                        (item) =>
                            item.status == WaitlistEntryStatus.active &&
                            item.status != WaitlistEntryStatus.cancelled,
                      )
                      .toList();
                  if (visible.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 44),
                        child: Text(
                          l10n.waitlistEmpty,
                          style: AppTypography.bodyMd,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = visible[index];
                      return _WaitlistCard(
                        entry: entry,
                        doctor: ref.watch(doctorProvider(entry.doctorId)).value,
                        busy: busyEntryId == entry.id,
                        onLeave: () => _leave(entry),
                        onAccept: entry.offeredSlotId == null
                            ? null
                            : () => _accept(entry),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leave(WaitlistEntry entry) async {
    setState(() => busyEntryId = entry.id);
    try {
      await ref.read(doctorsRepositoryProvider).leaveWaitlist(entry.id);
      ref.invalidate(waitlistEntriesProvider);
    } catch (_) {
      if (mounted) {
        showFormErrorSnackBar(
          context,
          AppLocalizations.of(context)!.waitlistActionError,
        );
      }
    } finally {
      if (mounted) setState(() => busyEntryId = null);
    }
  }

  Future<void> _accept(WaitlistEntry entry) async {
    final slotId = entry.offeredSlotId;
    if (slotId == null) return;
    setState(() => busyEntryId = entry.id);
    try {
      final appointment = await ref
          .read(doctorsRepositoryProvider)
          .claimWaitlistOffer(slotId: slotId, kind: AppointmentKind.videoCall);
      ref.invalidate(waitlistEntriesProvider);
      widget.onAppointmentClaimed?.call(appointment);
    } catch (_) {
      if (mounted) {
        showFormErrorSnackBar(
          context,
          AppLocalizations.of(context)!.waitlistActionError,
        );
      }
    } finally {
      if (mounted) setState(() => busyEntryId = null);
    }
  }
}

class _WaitlistCard extends StatelessWidget {
  const _WaitlistCard({
    required this.entry,
    required this.doctor,
    required this.busy,
    required this.onLeave,
    required this.onAccept,
  });

  final WaitlistEntry entry;
  final Doctor? doctor;
  final bool busy;
  final VoidCallback onLeave;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(doctor?.fullName ?? '…', style: AppTypography.sectionTitle),
            if (doctor != null) ...[
              const SizedBox(height: 4),
              Text(doctor!.specialty, style: AppTypography.cardItemMeta),
            ],
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.accentSofter,
                borderRadius: AppRadius.allPill,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Text(
                  entry.hasOffer
                      ? l10n.waitlistOfferStatus
                      : l10n.waitlistActiveStatus,
                  style: AppTypography.chipLabel,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (entry.hasOffer)
              PrimaryButton(
                label: l10n.waitlistAcceptAction,
                onPressed: busy ? null : onAccept,
              ),
            if (entry.hasOffer) const SizedBox(height: 8),
            TextButton(
              onPressed: busy ? null : onLeave,
              child: Text(l10n.waitlistLeaveAction),
            ),
          ],
        ),
      ),
    );
  }
}
