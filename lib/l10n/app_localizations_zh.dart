// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get privacyFirst => '隐私第一';

  @override
  String get permissionScreenBody => 'FastClean 直接在您的设备上分析您的照片。任何内容都不会上传到服务器。';

  @override
  String get grantAccessContinue => '授予访问权限并继续';

  @override
  String get homeScreenTitle => '主页';

  @override
  String get sortingMessageAnalyzing => '正在分析照片...';

  @override
  String get sortingMessageBlurry => '查找模糊的照片...';

  @override
  String get sortingMessageScreenshots => '识别截图...';

  @override
  String get sortingMessageDuplicates => '检测重复项...';

  @override
  String get sortingMessageScores => '计算分数...';

  @override
  String get sortingMessageCompiling => '正在编译结果...';

  @override
  String get sortingMessageRanking => '正在对您的照片进行排名...';

  @override
  String get sortingMessageFinalizing => '正在完成...';

  @override
  String get noMorePhotos => '没有更多可整理的照片了！';

  @override
  String errorOccurred(String error) {
    return '发生错误：$error';
  }

  @override
  String photosDeleted(int count, String space) {
    return '$count 张照片已删除，节省了 $space！';
  }

  @override
  String errorDeleting(String error) {
    return '删除时出错：$error';
  }

  @override
  String get reSort => '重新排序';

  @override
  String delete(int count) {
    return '删除 $count';
  }

  @override
  String get pass => '跳过';

  @override
  String get analyzePhotos => '分析照片';

  @override
  String fullScreenTitle(int count, int total) {
    return '$count / $total';
  }

  @override
  String get kept => '已保留';

  @override
  String get keep => '保留';

  @override
  String get failedToLoadImage => '加载图片失败';

  @override
  String get couldNotDelete => '无法删除照片。请稍后再试。';

  @override
  String get photoAccessRequired => '需要照片访问权限才能继续。';

  @override
  String get settings => '设置';

  @override
  String get storageUsed => '已用存储空间';

  @override
  String get spaceSavedThisMonth => '本月节省的空间';

  @override
  String get appTitle => 'FastClean';

  @override
  String get chooseYourLanguage => '选择您的语言';
}
