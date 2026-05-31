part of '../course_selection_page.dart';

class _CourseResultList extends StatelessWidget {
  const _CourseResultList({
    required this.courses,
    required this.isCourseSelected,
    required this.canSyncToTimetable,
    required this.onCourseTap,
    required this.onCourseSyncToggle,
  });

  final List<CourseItem> courses;
  final bool Function(CourseItem course) isCourseSelected;
  final bool Function(CourseItem course) canSyncToTimetable;
  final ValueChanged<CourseItem> onCourseTap;
  final ValueChanged<CourseItem> onCourseSyncToggle;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        _CourseSelectionPageContentState._horizontalPadding,
        4.0,
        _CourseSelectionPageContentState._horizontalPadding,
        20.0,
      ),
      sliver: SliverList.separated(
        addAutomaticKeepAlives: false,
        itemCount: courses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8.0),
        itemBuilder: (context, index) {
          final course = courses[index];
          return _CourseListTile(
            course: course,
            isSelected: isCourseSelected(course),
            canSyncToTimetable: canSyncToTimetable(course),
            alignActionsToBottom: false,
            onTap: () => onCourseTap(course),
            onSyncToggle: () => onCourseSyncToggle(course),
          );
        },
      ),
    );
  }
}

class _CourseResultGrid extends StatelessWidget {
  const _CourseResultGrid({
    required this.courses,
    required this.isCourseSelected,
    required this.canSyncToTimetable,
    required this.onCourseTap,
    required this.onCourseSyncToggle,
  });

  final List<CourseItem> courses;
  final bool Function(CourseItem course) isCourseSelected;
  final bool Function(CourseItem course) canSyncToTimetable;
  final ValueChanged<CourseItem> onCourseTap;
  final ValueChanged<CourseItem> onCourseSyncToggle;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        _CourseSelectionPageContentState._horizontalPadding,
        4.0,
        _CourseSelectionPageContentState._horizontalPadding,
        20.0,
      ),
      sliver: SliverGrid.builder(
        addAutomaticKeepAlives: false,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent:
              _CourseSelectionPageContentState._courseGridMaxExtent,
          mainAxisExtent: 214.0,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _CourseListTile(
            course: course,
            isSelected: isCourseSelected(course),
            canSyncToTimetable: canSyncToTimetable(course),
            alignActionsToBottom: true,
            onTap: () => onCourseTap(course),
            onSyncToggle: () => onCourseSyncToggle(course),
          );
        },
      ),
    );
  }
}

class _CoursePaginationControls extends StatelessWidget {
  const _CoursePaginationControls({required this.controller});

  final CourseSelectionController controller;

  @override
  Widget build(BuildContext context) {
    final isBusy = controller.isLoading || controller.isLoadingMore;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: isBusy || !controller.canGoToPreviousPage
              ? null
              : () => unawaited(controller.previousPage()),
          icon: const Icon(Icons.chevron_left),
          label: const Text('上一頁'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: controller.isLoadingMore
              ? const SizedBox.square(
                  dimension: 18.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : Text(
                  '${controller.currentPage} / ${controller.totalPages}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
        ),
        OutlinedButton.icon(
          onPressed: isBusy || !controller.canGoToNextPage
              ? null
              : () => unawaited(controller.nextPage()),
          icon: const Icon(Icons.chevron_right),
          label: const Text('下一頁'),
        ),
      ],
    );
  }
}
