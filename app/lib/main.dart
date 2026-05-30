import 'package:flutter/material.dart';
import 'package:magic_pinecone_course_demo/core/app/app_theme.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/presentation/course_selection_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CourseDemoApp());
}

String? courseShareCodeFromUri(Uri uri) {
  final shareCode = uri.queryParameters['c']?.trim();
  if (shareCode == null || shareCode.isEmpty) return null;
  return shareCode;
}

class CourseDemoApp extends StatelessWidget {
  const CourseDemoApp({super.key, this.initialUri});

  final Uri? initialUri;

  @override
  Widget build(BuildContext context) {
    final initialShareCode = courseShareCodeFromUri(initialUri ?? Uri.base);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Magic Pinecone Lite',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: CourseSelectionPage(initialShareCode: initialShareCode),
    );
  }
}
