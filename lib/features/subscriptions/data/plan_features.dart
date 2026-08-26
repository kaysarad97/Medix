import '../../../core/widgets/icon_chip.dart';
import '../../../shared/models/subscription_tier.dart';
import '../domain/entities/subscription_plan.dart';

/// Таблица сравнения тарифов с `design/Подписка.png`.
///
/// Лежит в `data/`, но приходит не с сервера: у API есть только код тарифа,
/// цена и два процента скидки — ни заголовков строк, ни подписей, ни иконок.
/// Поэтому содержимое таблицы одинаково у заглушки и у боевого репозитория.
///
/// Колонка Gold убрана вместе с тарифом. Семейный доступ был только у неё —
/// теперь он у Silver: единственная платная подписка, а в приложении семья
/// и так открывается любой действующей.
const List<PlanFeature> designPlanFeatures = [
  PlanFeature(
    title: 'Скидки на анализы',
    subtitle: 'в партнерских лабораториях',
    icon: MedixIcon.planDiscount,
    values: {SubscriptionTier.free: null, SubscriptionTier.silver: '5-7%'},
  ),
  PlanFeature(
    title: 'Скидка на консультации',
    subtitle: 'у проверенных врачей',
    icon: MedixIcon.planPrice,
    values: {SubscriptionTier.free: null, SubscriptionTier.silver: '10%'},
  ),
  PlanFeature(
    title: 'Очередь к врачу',
    subtitle: 'время ожидания приема',
    icon: MedixIcon.planQueue,
    values: {SubscriptionTier.free: 'Общая', SubscriptionTier.silver: 'Общая'},
  ),
  PlanFeature(
    title: 'Аналитика здоровья',
    subtitle: 'история заболевания',
    icon: MedixIcon.planAnalytics,
    values: {
      SubscriptionTier.free: null,
      SubscriptionTier.silver: 'Графики\n(история)',
    },
  ),
  PlanFeature(
    title: 'Семейный доступ',
    subtitle: 'мед-карты для',
    icon: MedixIcon.planFamily,
    values: {
      SubscriptionTier.free: null,
      SubscriptionTier.silver: 'До 3-5\nпрофилей',
    },
  ),
];
