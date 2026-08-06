/// Русские числительные с разным окончанием по последней цифре.
abstract final class RuPlurals {
  /// «1 год», «2 года», «5 лет», «11 лет».
  ///
  /// Нужно и профилю пользователя, и карточкам членов семьи — вынесено
  /// сюда, чтобы не разъезжалось между `UserProfile.ageLabel` и
  /// `FamilyMember.ageLabel`.
  static String years(int n) {
    final tail = n % 100;
    final last = n % 10;
    final String word;
    if (tail >= 11 && tail <= 14) {
      word = 'лет';
    } else if (last == 1) {
      word = 'год';
    } else if (last >= 2 && last <= 4) {
      word = 'года';
    } else {
      word = 'лет';
    }
    return '$n $word';
  }
}
