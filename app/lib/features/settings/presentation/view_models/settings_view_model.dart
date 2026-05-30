import 'package:flutter/material.dart';
import 'package:magic_pinecone_course_demo/core/app/app_theme.dart';
import 'package:magic_pinecone_course_demo/features/settings/data/settings_repository.dart';
import 'package:magic_pinecone_course_demo/features/settings/models/settings_models.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required this._appThemeController,
    required SettingsRepository repository,
  }) {
    _snapshot = repository.loadSettings();
    _appThemeController.addListener(_onThemeChanged);
  }

  final AppThemeController _appThemeController;
  late final SettingsSnapshot _snapshot;
  bool _omitWeekendsOnTimetable = true;

  String get appName => _snapshot.appName;
  String get appVersion => _snapshot.appVersion;
  String get summary => _snapshot.summary;
  List<SettingsStatusItem> get statusItems => _snapshot.statusItems;
  ThemeMode get themeMode => _appThemeController.value;
  bool get omitWeekendsOnTimetable => _omitWeekendsOnTimetable;

  void setDarkMode(bool enabled) {
    _appThemeController.setDarkMode(enabled);
  }

  void setOmitWeekendsOnTimetable(bool enabled) {
    if (_omitWeekendsOnTimetable == enabled) return;
    _omitWeekendsOnTimetable = enabled;
    notifyListeners();
  }

  void _onThemeChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _appThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }
}
