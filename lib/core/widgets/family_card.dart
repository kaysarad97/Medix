import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/models/family_member.dart';
import '../theme/app_colors.dart';
import '../utils/family_relation_labels.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'icon_chip.dart';
import 'section_header.dart';
import 'user_avatar.dart';

/// «Моя Семья» на экране «Ваша Мед-Карта»: список профилей близких.
///
/// Свёрстана по `design/Профиль - GOLD.png` — карточка идёт сразу за «Мои
/// Врачи». Строка на каждого: круглый аватар, имя и синяя подпись, кем он
/// приходится владельцу аккаунта.
///
/// Раньше на этом месте стоял горизонтальный переключатель с кружками —
/// макета на него не было, и он не совпал с присланным.
/// Что писать в строке участника.
enum FamilyRowStyle {
  /// «Имя Фамилия» и роль под ним — так на `design/Профиль - GOLD.png`,
  /// где карточка стоит среди своих же данных.
  name,

  /// «Профиль для ребенка» и «мед-карта и процедуры» под ним — так на
  /// главной, где это вход в чужой профиль, а не сведения о человеке.
  entry,
}

/// Размеры карточки. Живут здесь, а не в метриках профиля: карточка нужна
/// двум фичам сразу, и тянуть её размеры через `features/` нельзя.
///
/// Замеры по `design/Профиль - GOLD.png`, где карточка идёт после
/// «Мои Врачи», а плашка участника белая на сером теле карточки.
abstract final class FamilyCardMetrics {
  /// Радиус и внутренние поля — общие для карточек профиля.
  static const BorderRadius radius = BorderRadius.all(Radius.circular(14));
  static const double padding = 13;

  /// Строка: y 994…1056.
  static const double rowHeight = 62;

  /// Аватар — кружок 44 (краска x 44…88) при плашке, начинающейся с 34.
  static const double avatarSize = 44;
  static const double avatarLeft = 10;

  /// Аватар → текст: кружок кончается на 88, краска имени с 106.
  static const double avatarToText = 18;

  /// Заголовок → подпись под ним (краска 1011…1021 и 1034…1040).
  static const double titleToSubtitle = 4;

  /// Между строками участников. ЗАМЕРИТЬ НЕЧЕМ: в макете это место закрыто
  /// наложенным таб-баром — файл собран коллажем. Взят шаг карточек врачей
  /// (13), он же равен внутренним полям карточки.
  static const double rowGap = 13;
}

class FamilyCard extends StatelessWidget {
  const FamilyCard({
    super.key,
    required this.members,
    required this.title,
    this.rowStyle = FamilyRowStyle.name,
    this.onMemberTap,
    this.onTitleTap,
  });

  final List<FamilyMember> members;
  final String title;
  final FamilyRowStyle rowStyle;
  final ValueChanged<FamilyMember>? onMemberTap;

  /// Переход к списку целиком. Задан — в заголовке появляется шеврон, как у
  /// «Мед-карты» и «Ваших анализов». На главной не задаётся: там карточка
  /// сама и есть вход в профили близких.
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: FamilyCardMetrics.radius,
      padding: const EdgeInsets.all(FamilyCardMetrics.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            icon: MedixIcon.family,
            title: title,
            onTap: onTitleTap,
          ),
          for (final member in members) ...[
            const SizedBox(height: FamilyCardMetrics.rowGap),
            _MemberRow(
              member: member,
              style: rowStyle,
              onTap: onMemberTap == null ? null : () => onMemberTap!(member),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.style, this.onTap});

  final FamilyMember member;
  final FamilyRowStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: FamilyCardMetrics.rowHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: FamilyCardMetrics.radius,
          ),
          child: Row(
            children: [
              const SizedBox(width: FamilyCardMetrics.avatarLeft),
              UserAvatar(
                asset: member.avatarAsset,
                size: const Size.square(FamilyCardMetrics.avatarSize),
              ),
              const SizedBox(width: FamilyCardMetrics.avatarToText),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (style) {
                        FamilyRowStyle.name => member.fullName,
                        FamilyRowStyle.entry => member.relation.entryLabel(
                          l10n,
                        ),
                      },
                      style: AppTypography.cardItemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: FamilyCardMetrics.titleToSubtitle),
                    Text(
                      switch (style) {
                        FamilyRowStyle.name => member.relation.roleLabel(l10n),
                        FamilyRowStyle.entry => l10n.familyProfileHint,
                      },
                      style: AppTypography.tileSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FamilyCardMetrics.avatarLeft),
            ],
          ),
        ),
      ),
    );
  }
}
