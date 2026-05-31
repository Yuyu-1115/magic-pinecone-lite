import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_pinecone_course_demo/core/app/app_theme.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_repository.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_selection_storage.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_share_codec.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_supplemental_detail_catalog.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/models/course_detail_models.dart';
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

    await tester.tap(find.text('課表'));
    await tester.pumpAndSettle();

    expect(find.text('週六'), findsNothing);
    expect(find.text('週日'), findsNothing);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    expect(find.text('神奇松果 Lite'), findsWidgets);
    expect(find.text('深色模式'), findsOneWidget);
    expect(find.text('隱藏週末'), findsOneWidget);

    await tester.tap(find.widgetWithText(SwitchListTile, '深色模式'));
    await tester.pumpAndSettle();

    expect(themeController.value, ThemeMode.dark);

    await tester.tap(find.widgetWithText(SwitchListTile, '隱藏週末'));
    await tester.pumpAndSettle();

    expect(settingsViewModel.omitWeekendsOnTimetable, isFalse);

    await tester.tap(find.text('課表'));
    await tester.pumpAndSettle();

    expect(find.text('週六'), findsOneWidget);
    expect(find.text('週日'), findsOneWidget);
  });

  testWidgets('shared course links open the mobile timetable view', (
    tester,
  ) async {
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
    final shareCode = const CourseShareCodec().encodeSerialNos(['00001']);

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController,
        builder: (context, themeMode, _) => MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: CourseSelectionPage(
            controller: controller,
            initialShareCode: shareCode,
            settingsViewModel: settingsViewModel,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 1);
    expect(find.text('分享'), findsOneWidget);
  });

  testWidgets(
    'restore action discards shared preview and reloads saved courses',
    (tester) async {
      final controller = CourseSelectionController(
        repository: _FakeCourseRepository(
          result: const CourseSearchResult(
            totalCount: 2,
            courses: [
              CourseItem(
                serialNo: '00001',
                classNo: 'CS1001',
                title: '已儲存課程',
                credit: 3,
                teachers: ['王小明'],
                classTimes: ['1-1'],
              ),
              CourseItem(
                serialNo: '00002',
                classNo: 'CS1002',
                title: '分享預覽課程',
                credit: 3,
                teachers: ['陳小美'],
                classTimes: ['2-1'],
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
      final storage = MemoryCourseSelectionStorage();
      const shareCodec = CourseShareCodec();
      await storage.writeShareCode(shareCodec.encodeSerialNos(['00001']));

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (context, themeMode, _) => MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            home: CourseSelectionPage(
              controller: controller,
              courseSelectionStorage: storage,
              initialShareCode: shareCodec.encodeSerialNos(['00002']),
              settingsViewModel: settingsViewModel,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('分享預覽課程'), findsOneWidget);
      expect(find.text('已儲存課程'), findsNothing);
      expect(find.text('預覽'), findsOneWidget);

      await tester.tap(find.byTooltip('還原課表'));
      await tester.pumpAndSettle();

      expect(find.text('已儲存課程'), findsOneWidget);
      expect(find.text('分享預覽課程'), findsNothing);
      expect(find.text('預覽'), findsNothing);
      expect(find.byTooltip('還原課表'), findsNothing);
    },
  );

  testWidgets('share is disabled while timetable changes are unsaved', (
    tester,
  ) async {
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

    await tester.tap(find.text('程式設計'));
    await tester.pumpAndSettle();
    final detailSheet = find.byType(BottomSheet);
    await tester.tap(
      find.descendant(
        of: detailSheet,
        matching: find.widgetWithText(FilledButton, '加入'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: detailSheet,
        matching: find.widgetWithText(FilledButton, '關閉'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('課表'));
    await tester.pumpAndSettle();

    Finder shareInkWell() {
      return find.ancestor(of: find.text('分享'), matching: find.byType(InkWell));
    }

    expect(tester.widget<InkWell>(shareInkWell()).onTap, isNull);

    await tester.tap(find.text('分享'));
    await tester.pumpAndSettle();

    expect(find.textContaining('已複製分享連結'), findsNothing);

    await tester.tap(find.byTooltip('儲存課表'));
    await tester.pumpAndSettle();

    expect(tester.widget<InkWell>(shareInkWell()).onTap, isNotNull);
  });

  testWidgets('course detail dialog shows fallback when details are empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
            courseSupplementalDetailRepository:
                const _FakeCourseSupplementalDetailRepository(
                  detail: CourseSupplementalDetail(
                    serialNo: '00001',
                    objectives: '',
                    content: '',
                    books: '',
                    teachingMethod: '',
                    gradingPolicy: '',
                  ),
                ),
            settingsViewModel: settingsViewModel,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('程式設計'));
    await tester.pumpAndSettle();

    expect(find.text('尚未提供課程詳細資訊'), findsOneWidget);
    expect(find.text('目前沒有補充說明、指定用書或評分方式。'), findsOneWidget);
  });

  testWidgets('course detail sheet updates sync action label after toggling', (
    tester,
  ) async {
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

    await tester.tap(find.text('程式設計'));
    await tester.pumpAndSettle();

    final detailSheet = find.byType(BottomSheet);
    Finder syncButton(String label) {
      return find.descendant(
        of: detailSheet,
        matching: find.widgetWithText(FilledButton, label),
      );
    }

    expect(syncButton('加入'), findsOneWidget);
    expect(syncButton('移除'), findsNothing);

    await tester.tap(syncButton('加入'));
    await tester.pumpAndSettle();

    expect(syncButton('加入'), findsNothing);
    expect(syncButton('移除'), findsOneWidget);

    await tester.tap(syncButton('移除'));
    await tester.pumpAndSettle();

    expect(syncButton('加入'), findsOneWidget);
    expect(syncButton('移除'), findsNothing);
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

class _FakeCourseSupplementalDetailRepository
    implements CourseSupplementalDetailRepository {
  const _FakeCourseSupplementalDetailRepository({required this.detail});

  final CourseSupplementalDetail? detail;

  @override
  Future<CourseSupplementalDetail?> findBySerialNo(String serialNo) async {
    return detail;
  }
}
