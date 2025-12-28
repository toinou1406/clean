// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get privacyFirst => 'Конфіденційність перш за все';

  @override
  String get permissionScreenBody =>
      'SimpleClean аналізує ваші фотографії безпосередньо на вашому пристрої. Нічого ніколи не завантажується на сервер.';

  @override
  String get grantAccessContinue => 'Надати доступ і продовжити';

  @override
  String get homeScreenTitle => 'SimpleClean';

  @override
  String get sortingMessageAnalyzing => 'Аналіз метаданих фото...';

  @override
  String get sortingMessageBlurry => 'Виявлення розмитих зображень...';

  @override
  String get sortingMessageScreenshots => 'Пошук поганих знімків екрана...';

  @override
  String get sortingMessageDuplicates => 'Перевірка наявності дублікатів...';

  @override
  String get sortingMessageScores => 'Обчислення оцінок фотографій...';

  @override
  String get sortingMessageCompiling => 'Збір результатів...';

  @override
  String get sortingMessageRanking => 'Ранжування фотографій за «поганістю»...';

  @override
  String get sortingMessageFinalizing => 'Завершення вибору фотографій...';

  @override
  String get noMorePhotos => 'Більше не знайдено фотографій для видалення!';

  @override
  String errorOccurred(String error) {
    return 'Сталася помилка: $error';
  }

  @override
  String photosDeleted(int count, String space) {
    return 'Видалено $count фотографій і збережено $space';
  }

  @override
  String errorDeleting(String error) {
    return 'Помилка під час видалення фотографій: $error';
  }

  @override
  String get reSort => 'Повторне сортування';

  @override
  String delete(int count) {
    return 'Видалити ($count)';
  }

  @override
  String get pass => 'Пропустити';

  @override
  String get analyzePhotos => 'Аналізувати фотографії';

  @override
  String fullScreenTitle(int count, int total) {
    return '$count з $total';
  }

  @override
  String get kept => 'Збережено';

  @override
  String get keep => 'Зберегти';

  @override
  String get failedToLoadImage => 'Не вдалося завантажити зображення';

  @override
  String get couldNotDelete =>
      'Не вдалося видалити фотографії. Будь ласка спробуйте ще раз.';

  @override
  String get photoAccessRequired =>
      'Потрібен повний дозвіл на доступ до фотографій.';

  @override
  String get settings => 'Налаштування';

  @override
  String get storageUsed => 'Використано сховище';

  @override
  String get spaceSavedThisMonth => 'Збережено місця (цього місяця)';

  @override
  String get appTitle => 'SimpleClean';

  @override
  String get chooseYourLanguage => 'Виберіть свою мову';

  @override
  String get permissionTitle => 'Потрібен доступ до фотографій';

  @override
  String get permissionDescription =>
      'SimpleClean потребує доступу до ваших фотографій, щоб допомогти вам їх очистити.';

  @override
  String get grantPermission => 'Надати дозвіл';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionPermanentlyDenied =>
      'Photo access has been permanently denied. To continue, you must enable it in your device settings.';

  @override
  String get cancel => 'Cancel';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get totalSpaceSaved => 'Загалом заощаджено місця';

  @override
  String get readyToClean => 'Готові до очищення?';

  @override
  String get letsFindPhotos =>
      'Давайте знайдемо фотографії, які можна безпечно видалити.';

  @override
  String get storageSpaceSaved => 'Зекономлено';

  @override
  String get gridTutorialText =>
      'Торкніться, щоб переглянути на весь екран. Натисніть і утримуйте або двічі торкніться, щоб зберегти.';

  @override
  String get gridTutorialDismiss => 'Tap anywhere to continue';
}
