// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get privacyFirst => 'La privacidad primero';

  @override
  String get permissionScreenBody =>
      'SimpleClean analiza tus fotos directamente en tu dispositivo. Nada se sube a un servidor.';

  @override
  String get grantAccessContinue => 'Conceder acceso y continuar';

  @override
  String get homeScreenTitle => 'SimpleClean';

  @override
  String get sortingMessageAnalyzing => 'Analizando metadatos de fotos...';

  @override
  String get sortingMessageBlurry => 'Detectando imágenes borrosas...';

  @override
  String get sortingMessageScreenshots =>
      'Buscando capturas de pantalla malas...';

  @override
  String get sortingMessageDuplicates => 'Comprobando duplicados...';

  @override
  String get sortingMessageScores => 'Calculando puntuaciones de fotos...';

  @override
  String get sortingMessageCompiling => 'Compilando resultados...';

  @override
  String get sortingMessageRanking => 'Clasificando fotos por \'maldad\'...';

  @override
  String get sortingMessageFinalizing => 'Finalizando la selección de fotos...';

  @override
  String get noMorePhotos =>
      '¡No se encontraron más fotos que se puedan eliminar!';

  @override
  String errorOccurred(String error) {
    return 'Ocurrió un error: $error';
  }

  @override
  String photosDeleted(int count, String space) {
    return '$count fotos eliminadas y $space ahorrados';
  }

  @override
  String errorDeleting(String error) {
    return 'Error al eliminar fotos: $error';
  }

  @override
  String get reSort => 'Reordenar';

  @override
  String delete(int count) {
    return 'Eliminar ($count)';
  }

  @override
  String get pass => 'Pasar';

  @override
  String get analyzePhotos => 'Analizar fotos';

  @override
  String fullScreenTitle(int count, int total) {
    return '$count de $total';
  }

  @override
  String get kept => 'Guardada';

  @override
  String get keep => 'Guardar';

  @override
  String get failedToLoadImage => 'Error al cargar la imagen';

  @override
  String get couldNotDelete =>
      'No se pudieron eliminar las fotos. Por favor, inténtalo de nuevo.';

  @override
  String get photoAccessRequired =>
      'Se requiere permiso de acceso completo a las fotos.';

  @override
  String get settings => 'Ajustes';

  @override
  String get storageUsed => 'Almacenamiento usado';

  @override
  String get spaceSavedThisMonth => 'Espacio ahorrado (este mes)';

  @override
  String get appTitle => 'SimpleClean';

  @override
  String get chooseYourLanguage => 'Elige tu idioma';

  @override
  String get permissionTitle => 'Acceso a fotos requerido';

  @override
  String get permissionDescription =>
      'SimpleClean necesita acceso a tus fotos para ayudarte a limpiarlas.';

  @override
  String get grantPermission => 'Conceder permiso';

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
  String get totalSpaceSaved => 'Espacio total ahorrado';

  @override
  String get readyToClean => '¿Listo para limpiar?';

  @override
  String get letsFindPhotos =>
      'Busquemos algunas fotos que puedas eliminar de forma segura.';

  @override
  String get storageSpaceSaved => 'Ahorrado';

  @override
  String get gridTutorialText =>
      'Toca para ver en pantalla completa. Mantén presionado o toca dos veces para conservar.';

  @override
  String get gridTutorialDismiss => 'Tap anywhere to continue';
}
