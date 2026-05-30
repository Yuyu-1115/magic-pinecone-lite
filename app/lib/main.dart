import 'package:flutter/material.dart';
import 'package:magic_pinecone_course_demo/core/app/app_theme.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/presentation/course_selection_page.dart';
import 'package:magic_pinecone_course_demo/features/settings/data/settings_repository.dart';
import 'package:magic_pinecone_course_demo/features/settings/presentation/view_models/settings_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CourseDemoApp());
}

String? courseShareCodeFromUri(Uri uri) {
  final shareCode = uri.queryParameters['c']?.trim();
  if (shareCode == null || shareCode.isEmpty) return null;
  return shareCode;
}

class CourseDemoApp extends StatefulWidget {
  const CourseDemoApp({super.key, this.initialUri});

  final Uri? initialUri;

  @override
  State<CourseDemoApp> createState() => _CourseDemoAppState();
}

class _CourseDemoAppState extends State<CourseDemoApp> {
  late final AppThemeController _themeController;
  late final SettingsViewModel _settingsViewModel;

  @override
  void initState() {
    super.initState();
    _themeController = AppThemeController();
    _settingsViewModel = SettingsViewModel(
      appThemeController: _themeController,
      repository: const StaticSettingsRepository(),
    );
  }

  @override
  void dispose() {
    _settingsViewModel.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialShareCode = courseShareCodeFromUri(
      widget.initialUri ?? Uri.base,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeController,
      builder: (context, themeMode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Magic Pinecone Lite',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: CourseSelectionPage(
          initialShareCode: initialShareCode,
          settingsViewModel: _settingsViewModel,
        ),
      ),
    );
  }
}
