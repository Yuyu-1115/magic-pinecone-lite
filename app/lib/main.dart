import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magic_pinecone/core/app/app_providers.dart';
import 'package:magic_pinecone/core/app/app_theme.dart';
import 'package:magic_pinecone/features/course_selection/data/course_repository.dart';
import 'package:magic_pinecone/features/course_selection/presentation/lite_course_selection_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        courseRepositoryProvider.overrideWith((ref) {
          final dio = ref.watch(dioProvider);
          return StaticRemoteCourseRepository(dio: dio);
        }),
      ],
      child: const CourseDemoApp(),
    ),
  );
}

class CourseDemoApp extends ConsumerWidget {
  const CourseDemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeControllerProvider).value;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Magic Pinecone Lite',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const LiteCourseSelectionPage(),
    );
  }
}
