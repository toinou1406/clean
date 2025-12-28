// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get privacyFirst => 'Privacy First';

  @override
  String get permissionScreenBody =>
      'SimpleClean analyzes your photos directly on your device. Nothing is ever uploaded to a server.';

  @override
  String get grantAccessContinue => 'Grant Access & Continue';

  @override
  String get homeScreenTitle => 'SimpleClean';

  @override
  String get sortingMessageAnalyzing => 'Analyzing photo metadata...';

  @override
  String get sortingMessageBlurry => 'Detecting blurry images...';

  @override
  String get sortingMessageScreenshots => 'Searching for bad screenshots...';

  @override
  String get sortingMessageDuplicates => 'Checking for duplicates...';

  @override
  String get sortingMessageScores => 'Calculating photo scores...';

  @override
  String get sortingMessageCompiling => 'Compiling results...';

  @override
  String get sortingMessageRanking => 'Ranking photos by \'badness\'...';

  @override
  String get sortingMessageFinalizing => 'Finalizing the photo selection...';

  @override
  String get noMorePhotos => 'No more deletable photos found!';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String photosDeleted(int count, String space) {
    return 'Deleted $count photos and saved $space';
  }

  @override
  String errorDeleting(String error) {
    return 'Error deleting photos: $error';
  }

  @override
  String get reSort => 'Re-sort';

  @override
  String delete(int count) {
    return 'Delete ($count)';
  }

  @override
  String get pass => 'Pass';

  @override
  String get analyzePhotos => 'Analyze Photos';

  @override
  String fullScreenTitle(int count, int total) {
    return '$count of $total';
  }

  @override
  String get kept => 'Kept';

  @override
  String get keep => 'Keep';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get couldNotDelete => 'Could not delete photos. Please try again.';

  @override
  String get photoAccessRequired => 'Full photo access permission is required.';

  @override
  String get settings => 'Settings';

  @override
  String get storageUsed => 'Storage Used';

  @override
  String get spaceSavedThisMonth => 'Space Saved (This Month)';

  @override
  String get appTitle => 'SimpleClean';

  @override
  String get chooseYourLanguage => 'Choose your language';

  @override
  String get permissionTitle => 'Photo Access Required';

  @override
  String get permissionDescription =>
      'SimpleClean needs full access to your photos to work properly. Please choose \'Allow access to all photos\' when prompted.';

  @override
  String get grantPermission => 'Grant Permission';

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
  String get totalSpaceSaved => 'Total Space Saved';

  @override
  String get readyToClean => 'Ready to Clean?';

  @override
  String get letsFindPhotos => 'Let\'s find some photos you can safely delete.';

  @override
  String get storageSpaceSaved => 'Saved';

  @override
  String get gridTutorialText =>
      'Tap to see a photo fullscreen.\n\nLong-press or double-tap to keep it.';

  @override
  String get gridTutorialDismiss => 'Tap anywhere to continue';
}
