import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:magic_pinecone_course_demo/core/widgets/owned_change_notifier_builder.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_repository.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_schedule_repository.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_selection_storage.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_share_codec.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_share_url.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_share_url_cleaner.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/data/course_supplemental_detail_catalog.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/models/course_detail_models.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/models/course_schedule_models.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/presentation/view_models/course_selection_controller.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/presentation/widgets/calendar_item.dart';
import 'package:magic_pinecone_course_demo/features/settings/presentation/settings_page.dart';
import 'package:magic_pinecone_course_demo/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

part 'widgets/course_result_widgets.dart';
part 'widgets/course_timetable_view.dart';
part 'widgets/course_filter_widgets.dart';
part 'widgets/course_card_widgets.dart';
part 'widgets/course_state_widgets.dart';

class CourseSelectionPage extends StatelessWidget {
  const CourseSelectionPage({
    super.key,
    this.controller,
    this.courseSupplementalDetailRepository,
    this.courseSelectionStorage,
    required this.settingsViewModel,
    this.initialShareCode,
    this.showBackButton = false,
  });

  final CourseSelectionController? controller;
  final CourseSupplementalDetailRepository? courseSupplementalDetailRepository;
  final CourseSelectionStorage? courseSelectionStorage;
  final SettingsViewModel settingsViewModel;
  final String? initialShareCode;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final supplementalDetailRepository =
        courseSupplementalDetailRepository ??
        StaticRemoteCourseSupplementalDetailRepository(dio: Dio());
    final courseSelectionStorage =
        this.courseSelectionStorage ?? createCourseSelectionStorage();

    return OwnedChangeNotifierBuilder<CourseSelectionController>(
      notifier: controller,
      create: (context) => CourseSelectionController(
        repository: StaticRemoteCourseRepository(dio: Dio()),
      ),
      onReady: (controller) => unawaited(controller.load()),
      builder: (context, controller) => _CourseSelectionPageContent(
        controller: controller,
        supplementalDetailRepository: supplementalDetailRepository,
        courseSelectionStorage: courseSelectionStorage,
        settingsViewModel: settingsViewModel,
        initialShareCode: initialShareCode,
        showBackButton: showBackButton,
      ),
    );
  }
}

enum _CourseSelectionView { search, timetable, settings }

enum _CourseTypeFilter { all, required, elective }

enum _VacancyFilter { all, available, full }

class _CourseSelectionPageContent extends StatefulWidget {
  const _CourseSelectionPageContent({
    required this.controller,
    required this.supplementalDetailRepository,
    required this.courseSelectionStorage,
    required this.settingsViewModel,
    required this.initialShareCode,
    required this.showBackButton,
  });

  final CourseSelectionController controller;
  final CourseSupplementalDetailRepository supplementalDetailRepository;
  final CourseSelectionStorage courseSelectionStorage;
  final SettingsViewModel settingsViewModel;
  final String? initialShareCode;
  final bool showBackButton;

  @override
  State<_CourseSelectionPageContent> createState() =>
      _CourseSelectionPageContentState();
}

class _CourseSelectionPageContentState
    extends State<_CourseSelectionPageContent> {
  static const _horizontalPadding = 16.0;
  static const _wideLayoutMinWidth = 900.0;
  static const _desktopWorkspaceMinWidth = 1100.0;
  static const _desktopCoursePaneWidth = 520.0;
  static const _maxSearchContentWidth = 1180.0;
  static const _maxSheetWidth = 640.0;
  static const _maxAdvancedFilterDialogWidth = 1080.0;
  static const _maxCourseDetailsDialogWidth = 980.0;
  static const _courseDetailsDialogHeight = 680.0;
  static const _courseGridMaxExtent = 560.0;

  final CourseScheduleRepository _scheduleRepository =
      const StaticCourseScheduleRepository();
  final CourseShareCodec _shareCodec = const CourseShareCodec();
  final Map<String, CourseItem> _selectedCourses = {};
  _CourseSelectionView _selectedView = _CourseSelectionView.search;
  bool _onlyShowTimetableCompatibleCourses = false;
  bool _onlyShowSelectedCourses = false;
  bool _didRestoreSelectedCourses = false;
  bool _isPreviewingSharedCourses = false;
  bool _hasUnsavedCourseSelection = false;
  final Map<String, List<ScheduledCourse>> _courseScheduledCoursesCache = {};
  final Map<String, bool> _canSyncToTimetableCache = {};

  CourseSelectionController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, widget.settingsViewModel]),
      builder: (context, _) {
        if (controller.isLoading && controller.courses.isEmpty) {
          _courseScheduledCoursesCache.clear();
          _canSyncToTimetableCache.clear();
        }
        if (!controller.isLoading && !_didRestoreSelectedCourses) {
          _didRestoreSelectedCourses = true;
          unawaited(_restoreSelectedCourses());
        }
        final displayedCourses = _displayedCourses();
        return LayoutBuilder(
          builder: (context, constraints) {
            final useDesktopWorkspace =
                constraints.maxWidth >= _desktopWorkspaceMinWidth;
            if (useDesktopWorkspace) {
              return _buildDesktopWorkspace(context, displayedCourses);
            }
            return _buildMobileWorkspace(
              context,
              displayedCourses,
              useDesktopCourseDetails:
                  constraints.maxWidth >= _wideLayoutMinWidth,
            );
          },
        );
      },
    );
  }

  Widget _buildMobileWorkspace(
    BuildContext context,
    List<CourseItem> displayedCourses, {
    required bool useDesktopCourseDetails,
  }) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton ? const BackButton() : null,
        title: const Text(
          '神奇松果 Lite',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedView == _CourseSelectionView.search)
            IconButton(
              tooltip: '重新整理',
              onPressed: controller.isLoading
                  ? null
                  : () => unawaited(controller.search()),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: switch (_selectedView) {
        _CourseSelectionView.search => _buildCourseSearchView(
          displayedCourses,
          useDesktopCourseDetails: useDesktopCourseDetails,
          useAdvancedFilterDialog: useDesktopCourseDetails,
        ),
        _CourseSelectionView.timetable => _buildTimetableView(
          context,
          useDesktopDialog: useDesktopCourseDetails,
        ),
        _CourseSelectionView.settings => SettingsPage(
          viewModel: widget.settingsViewModel,
          showAppBar: false,
        ),
      },
      floatingActionButton: _buildMobileCourseSelectionActions(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedView.index,
        onDestinationSelected: (index) {
          setState(() {
            _selectedView = _CourseSelectionView.values[index];
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: '課程查詢'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '課表',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopWorkspace(
    BuildContext context,
    List<CourseItem> displayedCourses,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text(
          '神奇松果 Lite',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: '重新整理',
            onPressed: controller.isLoading
                ? null
                : () => unawaited(controller.search()),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '設定',
            onPressed: () => _showSettingsDialog(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: _desktopCoursePaneWidth,
            child: _buildCourseSearchView(
              displayedCourses,
              useDesktopCourseDetails: true,
              useAdvancedFilterDialog: true,
            ),
          ),
          VerticalDivider(
            width: 1.0,
            thickness: 1.0,
            color: colorScheme.outlineVariant,
          ),
          Expanded(child: _buildTimetableView(context, useDesktopDialog: true)),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) =>
            SettingsDialog(viewModel: widget.settingsViewModel),
      ),
    );
  }

  Widget _buildTimetableView(
    BuildContext context, {
    required bool useDesktopDialog,
  }) {
    final snapshot = _visibleScheduleSnapshot();
    return _CourseTimetableView(
      snapshot: snapshot,
      totalCredits: _selectedTotalCredits,
      conflictSlotCount: _conflictSlotCount(snapshot),
      showSaveAction: _canSaveCourseSelection && useDesktopDialog,
      showPreviewHint: _isPreviewingSharedCourses,
      onSavePressed: _saveCourseSelection,
      onDiscardPressed: _discardUnsavedCourseSelection,
      onSharePressed: _hasUnsavedCourseSelection ? null : _shareSelectedCourses,
      onCourseTap: (course) => _showTimetableCourseDetails(
        context,
        course,
        useDesktopDialog: useDesktopDialog,
      ),
    );
  }

  Widget? _buildMobileCourseSelectionActions() {
    if (!_canSaveCourseSelection ||
        _selectedView == _CourseSelectionView.settings) {
      return null;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'restore-course-selection',
          tooltip: '還原課表',
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
          onPressed: _discardUnsavedCourseSelection,
          child: const Icon(Icons.restore),
        ),
        const SizedBox(height: 12.0),
        FloatingActionButton(
          heroTag: 'save-course-selection',
          tooltip: '儲存課表',
          onPressed: _saveCourseSelection,
          child: const Icon(Icons.save_outlined),
        ),
      ],
    );
  }

  Widget _buildCourseSearchView(
    List<CourseItem> displayedCourses, {
    required bool useDesktopCourseDetails,
    required bool useAdvancedFilterDialog,
  }) {
    return _CourseSearchView(
      controller: controller,
      displayedCourses: displayedCourses,
      isCourseSelected: _isCourseSelected,
      canSyncToTimetable: _canSyncToTimetable,
      onCourseTap: (course) => _showCourseDetails(
        context,
        course,
        useDesktopDialog: useDesktopCourseDetails,
      ),
      onCourseSyncToggle: _toggleCourseSelection,
      onLocalFilterPressed: () =>
          _showLocalFilterSheet(context, useDialog: useAdvancedFilterDialog),
      localFilterActive:
          _onlyShowTimetableCompatibleCourses || _onlyShowSelectedCourses,
      localFilterTotalCount: _localFilterTotalCount,
      useAdvancedFilterDialog: useAdvancedFilterDialog,
    );
  }

  void _showCourseDetails(
    BuildContext context,
    CourseItem course, {
    required bool useDesktopDialog,
  }) {
    if (useDesktopDialog) {
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => _CourseDetailsDialog(
            course: course,
            supplementalDetail: widget.supplementalDetailRepository
                .findBySerialNo(course.serialNo),
            toggleCourseSelection: _toggleCourseSelection,
            isCourseSelected: _isCourseSelected,
          ),
        ),
      );
      return;
    }

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _CourseDetailsSheet(
          course: course,
          toggleCourseSelection: _toggleCourseSelection,
          isCourseSelected: _isCourseSelected,
        ),
      ),
    );
  }

  void _showTimetableCourseDetails(
    BuildContext context,
    ScheduledCourse scheduledCourse, {
    required bool useDesktopDialog,
  }) {
    final serialNo = scheduledCourse.serialNo;
    final course = serialNo == null ? null : _selectedCourses[serialNo];
    if (course != null) {
      _showCourseDetails(context, course, useDesktopDialog: useDesktopDialog);
      return;
    }

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) =>
            _ScheduledCourseDetailsSheet(course: scheduledCourse),
      ),
    );
  }

  Future<void> _showLocalFilterSheet(
    BuildContext context, {
    required bool useDialog,
  }) async {
    Widget buildContent(BuildContext context, {required bool useDialogLayout}) {
      return _LocalCourseFilterSheet(
        onlyShowTimetableCompatibleCourses: _onlyShowTimetableCompatibleCourses,
        onlyShowSelectedCourses: _onlyShowSelectedCourses,
        useDialogLayout: useDialogLayout,
      );
    }

    final nextValue = useDialog
        ? await showDialog<_LocalCourseFilterState>(
            context: context,
            builder: (context) {
              return Dialog(
                clipBehavior: Clip.antiAlias,
                insetPadding: const EdgeInsets.all(32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxSheetWidth),
                  child: buildContent(context, useDialogLayout: true),
                ),
              );
            },
          )
        : await showModalBottomSheet<_LocalCourseFilterState>(
            context: context,
            showDragHandle: true,
            builder: (context) {
              return buildContent(context, useDialogLayout: false);
            },
          );
    if (!mounted || nextValue == null) {
      return;
    }
    setState(() {
      _onlyShowTimetableCompatibleCourses =
          nextValue.onlyShowTimetableCompatibleCourses;
      _onlyShowSelectedCourses = nextValue.onlyShowSelectedCourses;
    });
  }

  List<ScheduledCourse> _getCachedScheduledCourses(
    CourseItem course,
    List<String> periods,
  ) {
    return _courseScheduledCoursesCache.putIfAbsent(
      course.serialNo,
      () => _courseToScheduledCourses(course, periods),
    );
  }

  List<CourseItem> _displayedCourses() {
    final courses = _onlyShowSelectedCourses
        ? _selectedCourses.values.toList(growable: false)
        : controller.courses;

    if (!_onlyShowTimetableCompatibleCourses) return courses;

    final currentSchedule = _syncedScheduleSnapshot();
    final occupiedSlots = currentSchedule.courses
        .expand(_occupiedSlots)
        .toSet();
    final periods = currentSchedule.periods;

    return courses
        .where(
          (course) =>
              _canFitCurrentTimetableCached(course, occupiedSlots, periods),
        )
        .toList(growable: false);
  }

  int get _localFilterTotalCount {
    if (_onlyShowSelectedCourses) return _selectedCourses.length;
    return controller.courses.length;
  }

  bool _isCourseSelected(CourseItem course) {
    return _selectedCourses.containsKey(course.serialNo);
  }

  int get _selectedTotalCredits {
    return _selectedCourses.values.fold(
      0,
      (total, course) => total + course.credit,
    );
  }

  bool _canSyncToTimetable(CourseItem course) {
    return _canSyncToTimetableCache.putIfAbsent(course.serialNo, () {
      final baseSchedule = _scheduleRepository.loadSchedule();
      return _getCachedScheduledCourses(
        course,
        baseSchedule.periods,
      ).isNotEmpty;
    });
  }

  bool _canFitCurrentTimetableCached(
    CourseItem course,
    Set<String> occupiedSlots,
    List<String> periods,
  ) {
    final candidateCourses = _getCachedScheduledCourses(course, periods);
    if (candidateCourses.isEmpty) return false;

    final candidateSlots = candidateCourses.expand(_occupiedSlots);
    return candidateSlots.every((slot) => !occupiedSlots.contains(slot));
  }

  Iterable<String> _occupiedSlots(ScheduledCourse course) sync* {
    for (var index = 0; index < course.length; index++) {
      yield '${course.dayIndex}:${course.startPeriodIndex + index}';
    }
  }

  int _conflictSlotCount(CourseScheduleSnapshot snapshot) {
    final slotCounts = <String, int>{};
    for (final course in snapshot.courses) {
      for (final slot in _occupiedSlots(course)) {
        slotCounts.update(slot, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return slotCounts.values.where((count) => count > 1).length;
  }

  Future<void> _shareSelectedCourses() async {
    final shareUrl = _selectedCourseShareUrl();
    await Clipboard.setData(ClipboardData(text: shareUrl.toString()));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已複製分享連結：$shareUrl')));
  }

  Uri _selectedCourseShareUrl() {
    final code = _selectedCourseShareCode();
    return buildCourseShareUrl(baseUri: Uri.base, code: code);
  }

  String _selectedCourseShareCode() {
    return _shareCodec.encodeSerialNos(_selectedCourses.keys);
  }

  void _toggleCourseSelection(CourseItem course) {
    setState(() {
      if (_selectedCourses.containsKey(course.serialNo)) {
        _selectedCourses.remove(course.serialNo);
      } else {
        _selectedCourses[course.serialNo] = course;
      }
      _hasUnsavedCourseSelection = true;
    });
  }

  bool get _canSaveCourseSelection {
    return _isPreviewingSharedCourses || _hasUnsavedCourseSelection;
  }

  Future<void> _persistSelectedCourses() async {
    final code = _selectedCourseShareCode();
    await widget.courseSelectionStorage.writeShareCode(code);
  }

  Future<void> _restoreSelectedCourses() async {
    final restoreState = await _initialShareCode();
    if (restoreState == null) return;

    await _restoreCourseSelection(restoreState);
  }

  Future<void> _restoreCourseSelection(
    _CourseShareRestoreState restoreState,
  ) async {
    final serialNos = _decodeShareCode(restoreState.code);
    if (serialNos == null) return;

    final courses = await controller.findCoursesBySerialNos(serialNos);
    if (!mounted || courses.isEmpty) return;

    if (restoreState.isPreview) {
      clearCourseShareCodeFromBrowserUrl();
    }

    setState(() {
      _isPreviewingSharedCourses = restoreState.isPreview;
      _hasUnsavedCourseSelection = false;
      if (restoreState.isPreview) {
        _selectedView = _CourseSelectionView.timetable;
      }
      _selectedCourses
        ..clear()
        ..addEntries(
          courses.map((course) => MapEntry(course.serialNo, course)),
        );
    });
    if (!restoreState.isPreview) {
      await widget.courseSelectionStorage.writeShareCode(restoreState.code);
    }
  }

  Future<void> _discardUnsavedCourseSelection() async {
    final storedCode = await widget.courseSelectionStorage.readShareCode();
    final normalizedStoredCode = storedCode?.trim();
    if (normalizedStoredCode == null || normalizedStoredCode.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isPreviewingSharedCourses = false;
        _hasUnsavedCourseSelection = false;
        _selectedCourses.clear();
      });
      return;
    }

    final restoreState = _CourseShareRestoreState(
      code: normalizedStoredCode,
      isPreview: false,
    );
    await _restoreCourseSelection(restoreState);
  }

  Future<void> _saveCourseSelection() async {
    await _persistSelectedCourses();
    if (!mounted) return;

    setState(() {
      _isPreviewingSharedCourses = false;
      _hasUnsavedCourseSelection = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已儲存課表')));
  }

  Future<_CourseShareRestoreState?> _initialShareCode() async {
    final sharedCode =
        widget.initialShareCode?.trim() ??
        Uri.base.queryParameters['c']?.trim();
    if (sharedCode != null && sharedCode.isNotEmpty) {
      return _CourseShareRestoreState(code: sharedCode, isPreview: true);
    }

    final storedCode = await widget.courseSelectionStorage.readShareCode();
    final normalizedStoredCode = storedCode?.trim();
    if (normalizedStoredCode == null || normalizedStoredCode.isEmpty) {
      return null;
    }
    return _CourseShareRestoreState(
      code: normalizedStoredCode,
      isPreview: false,
    );
  }

  List<String>? _decodeShareCode(String code) {
    try {
      return _shareCodec.decodeSerialNos(code);
    } on ArgumentError {
      return null;
    }
  }

  CourseScheduleSnapshot _syncedScheduleSnapshot() {
    final baseSchedule = _scheduleRepository.loadSchedule();
    final syncedCourses = _selectedCourses.values.expand(
      (course) => _getCachedScheduledCourses(course, baseSchedule.periods),
    );

    return CourseScheduleSnapshot(
      courses: [...baseSchedule.courses, ...syncedCourses],
      weekDays: baseSchedule.weekDays,
      periods: baseSchedule.periods,
    );
  }

  CourseScheduleSnapshot _visibleScheduleSnapshot() {
    final snapshot = _syncedScheduleSnapshot();
    if (!widget.settingsViewModel.omitWeekendsOnTimetable) return snapshot;

    return CourseScheduleSnapshot(
      courses: snapshot.courses
          .where((course) => course.dayIndex < 5)
          .toList(growable: false),
      weekDays: snapshot.weekDays.take(5).toList(growable: false),
      periods: snapshot.periods,
    );
  }

  List<ScheduledCourse> _courseToScheduledCourses(
    CourseItem course,
    List<String> periods,
  ) {
    final slots = <_CourseTimeSlot>[];

    for (final classTime in course.classTimes) {
      final parts = classTime.split('-');
      if (parts.length != 2) continue;

      final day = int.tryParse(parts[0]);
      if (day == null || day < 1 || day > 7) continue;

      final periodIndex = periods.indexOf(parts[1]);
      if (periodIndex < 0) continue;

      slots.add(_CourseTimeSlot(dayIndex: day - 1, periodIndex: periodIndex));
    }

    slots.sort((a, b) {
      final dayComparison = a.dayIndex.compareTo(b.dayIndex);
      if (dayComparison != 0) return dayComparison;
      return a.periodIndex.compareTo(b.periodIndex);
    });

    final courses = <ScheduledCourse>[];
    var index = 0;
    while (index < slots.length) {
      final start = slots[index];
      var length = 1;
      index += 1;

      while (index < slots.length &&
          slots[index].dayIndex == start.dayIndex &&
          slots[index].periodIndex == start.periodIndex + length) {
        length += 1;
        index += 1;
      }

      courses.add(
        ScheduledCourse(
          name: course.title,
          serialNo: course.serialNo,
          dayIndex: start.dayIndex,
          startPeriodIndex: start.periodIndex,
          length: length,
          location: course.classNo,
          category: course.courseTypeText,
        ),
      );
    }

    return courses;
  }
}

class _CourseShareRestoreState {
  const _CourseShareRestoreState({required this.code, required this.isPreview});

  final String code;
  final bool isPreview;
}

class _CourseTimeSlot {
  const _CourseTimeSlot({required this.dayIndex, required this.periodIndex});

  final int dayIndex;
  final int periodIndex;
}

class _CourseSearchView extends StatelessWidget {
  const _CourseSearchView({
    required this.controller,
    required this.displayedCourses,
    required this.isCourseSelected,
    required this.canSyncToTimetable,
    required this.onCourseTap,
    required this.onCourseSyncToggle,
    required this.onLocalFilterPressed,
    required this.localFilterActive,
    required this.localFilterTotalCount,
    required this.useAdvancedFilterDialog,
  });

  final CourseSelectionController controller;
  final List<CourseItem> displayedCourses;
  final bool Function(CourseItem course) isCourseSelected;
  final bool Function(CourseItem course) canSyncToTimetable;
  final ValueChanged<CourseItem> onCourseTap;
  final ValueChanged<CourseItem> onCourseSyncToggle;
  final VoidCallback onLocalFilterPressed;
  final bool localFilterActive;
  final int localFilterTotalCount;
  final bool useAdvancedFilterDialog;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid =
            constraints.maxWidth >=
            _CourseSelectionPageContentState._wideLayoutMinWidth;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _CourseSelectionPageContentState._maxSearchContentWidth,
            ),
            child: Column(
              children: [
                _SearchPanel(
                  controller: controller,
                  useAdvancedFilterDialog: useAdvancedFilterDialog,
                ),
                _ResultSummary(
                  controller: controller,
                  displayedCourseCount: displayedCourses.length,
                  localFilterActive: localFilterActive,
                  localFilterTotalCount: localFilterTotalCount,
                  onFilterPressed: onLocalFilterPressed,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.search,
                    child: CustomScrollView(
                      scrollCacheExtent: const ScrollCacheExtent.pixels(900.0),
                      slivers: [
                        if (controller.isLoading && controller.courses.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (controller.error != null &&
                            controller.courses.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _ErrorState(
                              onRetry: () => unawaited(controller.search()),
                            ),
                          )
                        else if (displayedCourses.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(),
                          )
                        else if (useGrid)
                          _CourseResultGrid(
                            courses: displayedCourses,
                            isCourseSelected: isCourseSelected,
                            canSyncToTimetable: canSyncToTimetable,
                            onCourseTap: onCourseTap,
                            onCourseSyncToggle: onCourseSyncToggle,
                          )
                        else
                          _CourseResultList(
                            courses: displayedCourses,
                            isCourseSelected: isCourseSelected,
                            canSyncToTimetable: canSyncToTimetable,
                            onCourseTap: onCourseTap,
                            onCourseSyncToggle: onCourseSyncToggle,
                          ),
                        if (!localFilterActive && controller.totalCount > 0)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                _CourseSelectionPageContentState
                                    ._horizontalPadding,
                                4.0,
                                _CourseSelectionPageContentState
                                    ._horizontalPadding,
                                24.0,
                              ),
                              child: _CoursePaginationControls(
                                controller: controller,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
