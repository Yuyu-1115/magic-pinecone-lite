import 'package:magic_pinecone_course_demo/features/course_selection/data/course_schedule_catalog.dart';
import 'package:magic_pinecone_course_demo/features/course_selection/models/course_schedule_models.dart';

abstract class CourseScheduleRepository {
  CourseScheduleSnapshot loadSchedule();
}

class StaticCourseScheduleRepository implements CourseScheduleRepository {
  const StaticCourseScheduleRepository();

  @override
  CourseScheduleSnapshot loadSchedule() {
    return const CourseScheduleSnapshot(
      courses: mockScheduledCourses,
      weekDays: timetableWeekDays,
      periods: timetablePeriods,
    );
  }
}
