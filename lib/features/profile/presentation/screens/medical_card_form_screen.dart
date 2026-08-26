import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/medical_card.dart';
import '../providers/profile_providers.dart';
import '../widgets/medical_card_metrics.dart';
import '../widgets/profile_metrics.dart';

/// Форма мед-карты — свёрстана по `design/Медкарта.png`.
///
/// Все поля необязательные: карта заводится пустой и дозаполняется по мере
/// визитов. Поэтому кнопка сохранения активна всегда, а валидации, кроме
/// числовых ограничений на рост и вес, нет.
class MedicalCardFormScreen extends ConsumerStatefulWidget {
  const MedicalCardFormScreen({super.key});

  @override
  ConsumerState<MedicalCardFormScreen> createState() =>
      _MedicalCardFormScreenState();
}

class _MedicalCardFormScreenState extends ConsumerState<MedicalCardFormScreen> {
  final _chronic = TextEditingController();
  final _allergies = TextEditingController();
  final _surgeries = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();

  BloodGroup? _bloodGroup;
  RhesusFactor? _rhesus;
  bool? _hasChronic;
  bool? _hasBadHabits;
  var _prefilled = false;
  var _saving = false;

  @override
  void dispose() {
    _chronic.dispose();
    _allergies.dispose();
    _surgeries.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _prefill(MedicalCard card) {
    _prefilled = true;
    _bloodGroup = card.bloodGroup;
    _rhesus = card.rhesus;
    _hasChronic = card.hasChronicDiseases;
    _hasBadHabits = card.hasBadHabits;
    _chronic.text = card.chronicDiseases ?? '';
    _allergies.text = card.allergies ?? '';
    _surgeries.text = card.surgeries ?? '';
    _height.text = card.heightCm?.toString() ?? '';
    _weight.text = card.weightKg?.toString() ?? '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final card = MedicalCard(
      bloodGroup: _bloodGroup,
      rhesus: _rhesus,
      hasChronicDiseases: _hasChronic,
      chronicDiseases: _chronic.text.trim(),
      heightCm: int.tryParse(_height.text),
      weightKg: int.tryParse(_weight.text),
      allergies: _allergies.text.trim(),
      surgeries: _surgeries.text.trim(),
      hasBadHabits: _hasBadHabits,
    );
    await ref.read(profileRepositoryProvider).saveMedicalCard(card);

    // Перечитываем карту после записи: без этого сохранённое видно только
    // после перезапуска приложения. На заглушке дефект не виден — она
    // хранит карту в памяти и отдаёт уже изменённую; поймано на живом API,
    // где рост и вес ушли на сервер, а карточка осталась с прочерками.
    ref.invalidate(medicalCardProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).maybePop();
  }

  /// Форма собирается методом, а не отдельным виджетом: она правит
  /// состояние экрана, а вызывать setState снаружи класса нельзя.
  Widget _buildForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Label(l10n.bloodGroupLabel),
        const SizedBox(height: MedicalCardMetrics.labelToControl),
        _BloodGroupRow(
          selected: _bloodGroup,
          onSelected: (value) => setState(() => _bloodGroup = value),
        ),
        const SizedBox(height: MedicalCardMetrics.controlToLabel),

        _Label(l10n.rhesusFactorLabel),
        const SizedBox(height: MedicalCardMetrics.labelToControl),
        _ChoiceRow(
          options: [
            for (final value in RhesusFactor.values)
              (
                label: value.label,
                selected: value == _rhesus,
                onTap: () => setState(() => _rhesus = value),
              ),
          ],
          height: MedicalCardMetrics.rhesusHeight,
          stretch: true,
        ),
        const SizedBox(height: MedicalCardMetrics.controlToLabel),

        _Label(l10n.chronicDiseasesLabel),
        const SizedBox(height: MedicalCardMetrics.labelToControl),
        _YesNoRow(
          value: _hasChronic,
          l10n: l10n,
          onChanged: (value) => setState(() => _hasChronic = value),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.chronicDiseasesDetailPrompt,
          style: AppTypography.tileSubtitle.copyWith(
            color: AppColors.primaryBright,
          ),
        ),
        const SizedBox(height: MedicalCardMetrics.labelToControl),
        _TextField(controller: _chronic),
        const SizedBox(height: MedicalCardMetrics.controlToLabel),

        Row(
          children: [
            SizedBox(
              width: MedicalCardMetrics.yesNoWidth,
              child: _Label(l10n.heightFieldLabel),
            ),
            const SizedBox(width: MedicalCardMetrics.yesNoGap),
            _Label(l10n.weightFieldLabel),
          ],
        ),
        const SizedBox(height: MedicalCardMetrics.labelToControl),
        Row(
          children: [
            _NumberField(controller: _height, unit: 'см', hint: '——––––'),
            const SizedBox(width: MedicalCardMetrics.yesNoGap),
            _NumberField(controller: _weight, unit: 'кг', hint: '––––'),
          ],
        ),
        const SizedBox(height: MedicalCardMetrics.controlToLabel),

        _Label(l10n.allergiesLabel),
        const SizedBox(height: MedicalCardMetrics.labelToControl),
        _TextField(controller: _allergies),
        const SizedBox(height: MedicalCardMetrics.controlToLabel),

        _Label(l10n.surgeriesLabel),
        const SizedBox(height: MedicalCardMetrics.labelToControl),
        _TextField(controller: _surgeries),
        const SizedBox(height: MedicalCardMetrics.controlToLabel),

        _Label(l10n.badHabitsLabel),
        const SizedBox(height: MedicalCardMetrics.labelToControl),
        _YesNoRow(
          value: _hasBadHabits,
          l10n: l10n,
          onChanged: (value) => setState(() => _hasBadHabits = value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = ref.watch(medicalCardProvider).value;
    if (card != null && !_prefilled) _prefill(card);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              ScreenTopBar(
                title: l10n.yourMedicalCardTitle,
                onBack: () => Navigator.of(context).maybePop(),
                trailing: const AppIcon(
                  icon: MedixIcon.settings,
                  size: 22,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProfileMetrics.screenH,
                ),
                child: AppCard(
                  borderRadius: ProfileMetrics.allRadius,
                  padding: const EdgeInsets.all(MedicalCardMetrics.cardPadding),
                  child: _buildForm(),
                ),
              ),
              const SizedBox(height: MedicalCardMetrics.saveButtonTop),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProfileMetrics.screenH,
                ),
                child: PrimaryButton(
                  label: l10n.saveButtonLabel,
                  isLoading: _saving,
                  onPressed: _save,
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: AppTypography.bodyMd);
}

/// Четыре бокса группы крови в ряд.
class _BloodGroupRow extends StatelessWidget {
  const _BloodGroupRow({required this.selected, required this.onSelected});

  final BloodGroup? selected;
  final ValueChanged<BloodGroup> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final group in BloodGroup.values) ...[
            if (group != BloodGroup.values.first)
              const SizedBox(width: MedicalCardMetrics.bloodBoxGap),
            _Box(
              label: group.label,
              selected: group == selected,
              onTap: () => onSelected(group),
            ),
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MedicalCardMetrics.bloodBoxWidth,
      height: MedicalCardMetrics.bloodBoxHeight,
      child: Material(
        color: selected ? AppColors.primaryBright : AppColors.surfaceWhite,
        borderRadius: ProfileMetrics.allRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: selected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Пара кнопок «выбрано / не выбрано». Выбранная залита синим.
typedef _Option = ({String label, bool selected, VoidCallback onTap});

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.options,
    required this.height,
    this.stretch = false,
  });

  final List<_Option> options;
  final double height;

  /// Растянуть на всю ширину карточки (резус-фактор) или оставить узкими
  /// (да/нет) — в макете это разные ширины.
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    for (final option in options) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: MedicalCardMetrics.yesNoGap));
      }
      final button = _ChoiceButton(option: option, height: height);
      buttons.add(
        stretch
            ? Expanded(child: button)
            : SizedBox(width: MedicalCardMetrics.yesNoWidth, child: button),
      );
    }
    return Row(children: buttons);
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.option, required this.height});

  final _Option option;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: option.selected
            ? AppColors.primaryBright
            : AppColors.surfaceWhite,
        borderRadius: ProfileMetrics.allRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: option.onTap,
          child: Center(
            child: Text(
              option.label,
              style: AppTypography.tileTitle.copyWith(
                color: option.selected
                    ? AppColors.textOnPrimary
                    : AppColors.primaryBright,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YesNoRow extends StatelessWidget {
  const _YesNoRow({
    required this.value,
    required this.l10n,
    required this.onChanged,
  });

  /// `null` — пользователь ещё не отвечал; тогда обе кнопки белые.
  final bool? value;
  final AppLocalizations l10n;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ChoiceRow(
      height: MedicalCardMetrics.yesNoHeight,
      options: [
        (
          label: l10n.yesLabel,
          selected: value == true,
          onTap: () => onChanged(true),
        ),
        (
          label: l10n.noLabel,
          selected: value == false,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

/// Однострочное поле с прочерком вместо подсказки — так в макете.
class _TextField extends StatelessWidget {
  const _TextField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MedicalCardMetrics.fieldWidth,
      height: MedicalCardMetrics.fieldHeight,
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
              style: AppTypography.bodyMd,
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '-',
                hintStyle: AppTypography.placeholder.copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Поле роста или веса: число, единица и стрелки-степпер.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.unit,
    required this.hint,
  });

  final TextEditingController controller;
  final String unit;
  final String hint;

  void _step(int delta) {
    final current = int.tryParse(controller.text) ?? 0;
    final next = (current + delta).clamp(0, 300);
    controller.text = next == 0 ? '' : next.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MedicalCardMetrics.yesNoWidth,
      height: MedicalCardMetrics.numberFieldHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: ProfileMetrics.allRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.bodyMd,
                  cursorColor: AppColors.accent,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppTypography.placeholder.copyWith(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(unit, style: AppTypography.bodyMd),
              const SizedBox(width: 8),
              _Stepper(onUp: () => _step(1), onDown: () => _step(-1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.onUp, required this.onDown});

  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onUp,
          child: const Icon(
            Icons.keyboard_arrow_up,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        GestureDetector(
          onTap: onDown,
          child: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
