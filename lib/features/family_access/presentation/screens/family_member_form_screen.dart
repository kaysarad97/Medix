import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
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
/// Свёрстан по `design/Данные о родственниках.png` (440×956). Это шаг
/// регистрации без прогресс-бара: замеры совпали до пикселя — заголовок с
/// 260, карточка 355…585 с полями по 59 и шагом 14, кнопка 330×55 через 45
/// после карточки.
///
/// Полей ровно три, и макет это подтвердил: имя, дата рождения и родство —
/// ровно то, что принимает бэкенд. Пол, рост и вес, которые показывает
/// карточка члена семьи, не спрашиваются: сервер их не хранит.
///
/// РАСХОЖДЕНИЕ С МАКЕТОМ, ОСОЗНАННОЕ. Подпись поля даты обещает формат
/// «dd/mm/yyyy», будто его набирают руками, но открывается календарь — как
/// на шаге регистрации, где решение то же и по той же причине: вслепую
/// набранная дата отдаёт 422 с сервера, а промахнуться в календаре нельзя.
/// Подпись оставлена дизайнерская: она описывает вид значения, и календарь
/// заполняет поле ровно в этом формате.
///
/// ВТОРОЕ РАСХОЖДЕНИЕ. В макете заголовок стоит в одну строку, у нас
/// переносится на две, и всё под ним съезжает на высоту строки. Причина не в
/// вёрстке: [AppTypography.h1] несёт межбуквенный интервал 0,5, и «Данные
/// родственника» перестаёт влезать в 400 точек ровно на нём. Ломать общий
/// стиль ради одного экрана хуже, чем перенос: на реальном телефоне (393
/// точки против макетных 440) заголовок такой длины переносится в любом
/// случае.
///
/// Правка своего макета не имеет — та же форма с подставленными значениями
/// и другим заголовком. Удаление здесь когда-то было красной надписью под
/// кнопкой «Далее», но в обновлённых макетах «Моя Семья» дизайнер поставил
/// его кнопкой внизу карточки члена семьи — там оно теперь и живёт.
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

  /// Стрелка «назад» стоит там же, где на остальных внутренних экранах.
  static const double _backArrowTop = 36;

  /// Низ строки со стрелкой (132) → заголовок 260.
  static const double _backArrowToTitle = 128;

  /// Заголовок 260…304 → карточка 355.
  static const double _titleToCard = 50;

  /// Карточка 355…585 → кнопка 630.
  static const double _cardToButton = 45;

  /// Низ поля → верх следующего: поля 368…426, 441…499, 514…572.
  static const double _fieldGap = 14;

  /// Карточка 17…420 при полях 32…405.
  static const EdgeInsets _cardPadding = EdgeInsets.fromLTRB(13, 14, 13, 14);

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
              const SizedBox(height: _backArrowTop),
              // РАСХОЖДЕНИЕ С МАКЕТОМ, ОСОЗНАННОЕ. Стрелки «назад» в макете
              // нет — он повторяет шаг регистрации, а там уходят вперёд, и
              // возвращаться некуда. Здесь же форма открывается из списка
              // семьи и из карточки близкого: без стрелки экран становится
              // тупиком, из которого выбираются только системным жестом.
              // Строка без заголовка: он ниже, крупный, как в макете.
              ScreenTopBar(
                title: '',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: _backArrowToTitle),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Text(
                  _isEditing ? l10n.familyEditTitle : l10n.relativeDataTitle,
                  style: AppTypography.h1,
                ),
              ),
              const SizedBox(height: _titleToCard),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: AppCard(
                  padding: _cardPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        hint: l10n.relativeNameHint,
                        height: AppTextField.compactFieldHeight,
                        controller: _fullNameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        errorText: _fullNameError,
                        onChanged: (_) => setState(() => _fullNameError = null),
                      ),
                      const SizedBox(height: _fieldGap),
                      // Календарь вместо ручного ввода — см. расхождение с
                      // макетом в описании экрана.
                      GestureDetector(
                        onTap: _pickBirthDate,
                        child: AbsorbPointer(
                          child: AppTextField(
                            hint: l10n.relativeBirthDateHint,
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
              // Кнопка в макете не во всю ширину: 330 по центру, как на
              // шагах регистрации. Надпись там же — «Далее» со стрелкой,
              // хотя шаг последний и следующего экрана нет.
              Center(
                child: SizedBox(
                  width: PrimaryButton.mediumWidth,
                  child: PrimaryButton(
                    label: l10n.nextButtonLabel,
                    trailingIcon: Icons.arrow_forward,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _prefill(FamilyMember member) {
    _prefilled = true;
    _fullNameController.text = member.fullName;
    _relationController.text = member.relationshipLabel ?? '';
    _birthDate = member.birthDate;
    _birthDateController.text = _displayDate(member.birthDate);
  }

  /// Через косые черты — в том виде, который обещает подпись поля.
  static String _displayDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
    if (!mounted) return;

    // Закрывать нечего — снимаем ожидание с кнопки, чтобы она не осталась
    // крутиться навсегда. Так бывает по прямой ссылке и в тестах.
    if (!await Navigator.of(context).maybePop() && mounted) {
      setState(() => _isSaving = false);
    }
  }
}
