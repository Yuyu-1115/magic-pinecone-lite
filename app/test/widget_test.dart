import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_pinecone_course_demo/core/app/app_theme.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_repository.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/models/course_schedule_models.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/presentation/course_selection_page.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/presentation/view_models/course_selection_controller.dart';
import 'package:magic_pinecone_course_demo/features/settings/data/settings_repository.dart';
import 'package:magic_pinecone_course_demo/features/settings/presentation/view_models/settings_view_model.dart';

void main() {
  testWidgets('shows the course selection app shell', (tester) async {
    final controller = CourseSelectionController(
      repository: _FakeCourseRepository(
        result: const CourseSearchResult(
          totalCount: 1,
          courses: [
            CourseItem(
              serialNo: '00001',
              classNo: 'CS1001',
              title: '程式設計',
              credit: 3,
              teachers: ['王小明'],
              classTimes: ['1-1'],
            ),
          ],
        ),
      ),
    );
    addTearDown(controller.dispose);
    final themeController = AppThemeController();
    addTearDown(themeController.dispose);
    final settingsViewModel = SettingsViewModel(
      appThemeController: themeController,
      repository: const StaticSettingsRepository(),
    );
    addTearDown(settingsViewModel.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController,
        builder: (context, themeMode, _) => MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: CourseSelectionPage(
            controller: controller,
            settingsViewModel: settingsViewModel,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('課程查詢'), findsWidgets);
    expect(find.text('程式設計'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    expect(find.text('神奇松果 Lite'), findsWidgets);
    expect(find.text('深色模式'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(themeController.value, ThemeMode.dark);
  });
}

class _FakeCourseRepository implements CourseRepository {
  const _FakeCourseRepository({required this.result});

  final CourseSearchResult result;

  @override
  Future<CourseSearchResult> searchCourses({
    String? keyword,
    String? classNo,
    String? serialNo,
    String? departmentName,
    String? collegeName,
    String? instructor,
    String? courseType,
    List<int>? credits,
    bool? hasVacancy,
    List<String>? classTimes,
    int offset = 0,
    int limit = 100,
  }) async {
    return result;
  }
}
