import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/family_member.dart';
import '../../domain/entities/family_member_draft.dart';
import '../providers/family_providers.dart';

/// Форма члена семьи: добавление и правка одним экраном.
///
/// МАКЕТА НЕТ — см. [FamilyListScreen]. Поля собраны как на шаге регистрации
/// (`design/Ваши Данные.png`): карточка с полями и кнопка под ней.
///
/// Полей ровно три, потому что столько принимает бэкенд: ФИО, дата рождения
/// и родство. Пол, рост и вес, которые показывает карточка члена семьи,
/// здесь не спрашиваются: сервер их не хранит, и введённое пропало бы при
/// первом же чтении списка.
///
/// Состояние живёт в самом экране, а не в Notifier'е, как у логина и
/// регистрации: там форма размазана по нескольким экранам и должна их
/// пережить, здесь всё начинается и кончается на одном.
class FamilyMemberFormScreen extends ConsumerStatefulWidget {
  const FamilyMemberFormScreen({super.key, this.memberId});

  /// `null` — форма нового члена семьи.
  final String? memberId;

  @override
  ConsumerState<FamilyMemberFormScreen> createState() =>
      _FamilyMemberFormScreenState();
}

class _FamilyMemberFormScreenState
    extends ConsumerState<FamilyMemberFormScreen> {
  final _fullNameController = TextEditingController();
  final _relationController = TextEditingController();
  final _birthDateController = TextEditingController();

  DateTime? _birthDate;
  String? _fullNameError;
  String? _birthDateError;
  String? _relationError;
  bool _isSaving = false;

  /// Данные подставляются один раз: список членов семьи перечитывается после
  /// сохранения, и без этого флага правка затиралась бы на полпути.
  bool _prefilled = false;

  /// Отступы — как на шаге регистрации.
  static const double _topBarTop = 36;
  static const double _topBarToCard = 26;
  static const double _cardToButton = 44;
  static const double _fieldGap = 14;

  bool get _isEditing => widget.memberId != null;

  @override
  void dispose() {
    _fullNameController.dispose();
    _relationController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isEditing && !_prefilled) {
      final member = ref.watch(familyMemberProvider(widget.memberId!)).value;
      if (member != null) _prefill(member);
    }

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _topBarTop),
              ScreenTopBar(
                title: _isEditing ? l10n.familyEditTitle : l10n.familyAddTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: _topBarToCard),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        hint: l10n.fullNameHint,
                        height: AppTextField.compactFieldHeight,
                        controller: _fullNameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        errorText: _fullNameError,
                        onChanged: (_) => setState(() => _fullNameError = null),
                      ),
                      const SizedBox(height: _fieldGap),
                      // Дата выбирается календарём, как при регистрации:
                      // формат сервера «ГГГГ-ММ-ДД» вслепую не набрать.
                      GestureDetector(
                        onTap: _pickBirthDate,
                        child: AbsorbPointer(
                          child: AppTextField(
                            hint: l10n.birthDateHint,
                            height: AppTextField.compactFieldHeight,
                            controller: _birthDateController,
                            errorText: _birthDateError,
                          ),
                        ),
                      ),
                      const SizedBox(height: _fieldGap),
                      AppTextField(
                        hint: l10n.relationshipPlaceholder,
                        height: AppTextField.compactFieldHeight,
                        controller: _relationController,
                        textInputAction: TextInputAction.done,
                        errorText: _relationError,
                        onChanged: (_) => setState(() => _relationError = null),
                        onSubmitted: (_) => _save(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: _cardToButton),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: PrimaryButton(
                  label: l10n.saveButtonLabel,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _isSaving ? null : _confirmDelete,
                    child: Text(
                      l10n.familyDeleteButton,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _prefill(FamilyMember member) {
    _prefilled = true;
    _fullNameController.text = [
      member.lastName,
      member.firstName,
    ].where((part) => part.isNotEmpty).join(' ');
    _relationController.text = member.relationshipLabel ?? '';
    _birthDate = member.birthDate;
    _birthDateController.text = _displayDate(member.birthDate);
  }

  static String _displayDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  /// Календарь открывается на десяти годах назад: члены семьи — чаще всего
  /// дети, начинать с сегодняшнего дня значило бы всегда крутить назад.
  static const int _defaultAgeYears = 10;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ??
          DateTime(now.year - _defaultAgeYears, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _birthDate = picked;
      _birthDateError = null;
      _birthDateController.text = _displayDate(picked);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final fullName = _fullNameController.text.trim();
    final relation = _relationController.text.trim();
    final fullNameError = Validators.fullName(fullName);
    final relationError = Validators.familyRelation(relation);
    final birthDateError = _birthDate == null
        ? Validators.birthDate(null)
        : null;

    if (fullNameError != null ||
        relationError != null ||
        birthDateError != null) {
      setState(() {
        _fullNameError = fullNameError;
        _relationError = relationError;
        _birthDateError = birthDateError;
      });
      return;
    }

    setState(() => _isSaving = true);
    final repository = ref.read(familyRepositoryProvider);
    final draft = FamilyMemberDraft(
      fullName: fullName,
      birthDate: _birthDate!,
      relation: relation,
    );

    try {
      if (_isEditing) {
        await repository.update(widget.memberId!, draft);
      } else {
        await repository.add(draft);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showFormErrorSnackBar(context, e.message);
      return;
    }

    // Список перечитывается после любой правки: карточка члена семьи и обе
    // карточки «Моя Семья» читают его же.
    ref.invalidate(familyMembersProvider);
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.familyDeleteConfirmTitle),
        content: Text(l10n.familyDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.deleteButtonLabel,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(familyRepositoryProvider).remove(widget.memberId!);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showFormErrorSnackBar(context, e.message);
      return;
    }

    ref.invalidate(familyMembersProvider);
    // Не `pop`: под формой лежит карточка удалённого члена семьи, и
    // возвращаться на неё некуда.
    if (mounted) context.go(Routes.family);
  }
}
