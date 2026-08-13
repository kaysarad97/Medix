import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor_schedule.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';

void main() {
  ProviderContainer container() {
    final result = ProviderContainer();
    addTearDown(result.dispose);
    return result;
  }

  group('листание недель расписания', () {
    test('начинается с текущей', () {
      expect(container().read(scheduleWeekOffsetProvider), 0);
    });

    test('вперёд листается без предела', () {
      final ref = container();
      final notifier = ref.read(scheduleWeekOffsetProvider.notifier);

      notifier.next();
      notifier.next();

      expect(ref.read(scheduleWeekOffsetProvider), 2);
    });

    test('назад с текущей недели не уходит', () {
      final ref = container();
      final notifier = ref.read(scheduleWeekOffsetProvider.notifier);

      notifier.previous();

      // Записаться в прошлое некуда, поэтому ноль — нижняя граница.
      expect(ref.read(scheduleWeekOffsetProvider), 0);
    });

    test('назад возвращает на предыдущую, если листали вперёд', () {
      final ref = container();
      final notifier = ref.read(scheduleWeekOffsetProvider.notifier);

      notifier.next();
      notifier.previous();

      expect(ref.read(scheduleWeekOffsetProvider), 0);
    });
  });

  group('свой отзыв', () {
    test('встаёт первым в списке', () {
      final ref = container();
      final notifier = ref.read(composedReviewsProvider.notifier);

      notifier.add(text: 'Первый', authorName: 'Имя Фамилия', rating: 4);
      notifier.add(text: 'Второй', authorName: 'Имя Фамилия', rating: 5);

      final reviews = ref.read(composedReviewsProvider);
      expect(reviews.map((r) => r.text), ['Второй', 'Первый']);
      expect(reviews.first.authorName, 'Имя Фамилия');
    });

    test('пустая строка не отправляется', () {
      final ref = container();

      ref
          .read(composedReviewsProvider.notifier)
          .add(text: '   ', authorName: 'Имя Фамилия', rating: 5);

      expect(ref.read(composedReviewsProvider), isEmpty);
    });

    test('пробелы по краям обрезаются', () {
      final ref = container();

      ref
          .read(composedReviewsProvider.notifier)
          .add(text: '  Хороший врач  ', authorName: 'Имя Фамилия', rating: 5);

      expect(ref.read(composedReviewsProvider).single.text, 'Хороший врач');
    });

    test('оценка и дата попадают в отзыв', () {
      final ref = container();

      ref
          .read(composedReviewsProvider.notifier)
          .add(text: 'Хороший врач', authorName: 'Имя Фамилия', rating: 3);

      final review = ref.read(composedReviewsProvider).single;
      expect(review.rating, 3);
      // Дата проставляется сама: в макете она стоит под текстом отзыва.
      expect(review.dateLabel, isNotNull);
    });
  });

  group('выбор дня и времени', () {
    test('сбрасывается вместе с листанием недели', () {
      final ref = container();
      final selection = ref.read(scheduleSelectionProvider.notifier);

      selection.selectSlot(
        ScheduleSlot(id: 's1', startsAt: DateTime(2026, 8, 12, 12, 30)),
      );
      expect(ref.read(scheduleSelectionProvider).slot, isNotNull);

      selection.reset();

      // Иначе подсветка осталась бы на числе из прошлой ленты.
      expect(ref.read(scheduleSelectionProvider).slot, isNull);
      expect(ref.read(scheduleSelectionProvider).day, isNull);
    });
  });
}
