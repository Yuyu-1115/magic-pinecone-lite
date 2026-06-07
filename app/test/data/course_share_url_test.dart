import 'package:flutter_test/flutter_test.dart';
import 'package:magic_pinecone/features/course_selection/data/course_share_url.dart';

void main() {
  test(
    'buildCourseShareUrl uses GitHub Pages project path with share code',
    () {
      final shareUrl = buildCourseShareUrl(
        baseUri: Uri.parse(
          'https://magic-pinecone.github.io/magic-pinecone-lite/',
        ),
        code: 'Z21EeqHRw',
      );

      expect(
        shareUrl.toString(),
        'https://magic-pinecone.github.io/magic-pinecone-lite?c=Z21EeqHRw#',
      );
    },
  );

  test('buildCourseShareUrl falls back to production URL on localhost', () {
    final shareUrl = buildCourseShareUrl(
      baseUri: Uri.parse('http://localhost:5173/'),
      code: 'Z21EeqHRw',
    );

    expect(
      shareUrl.toString(),
      'https://magic-pinecone.github.io/magic-pinecone-lite?c=Z21EeqHRw#',
    );
  });

  test('removeCourseShareCode clears only the shared course parameter', () {
    final cleanUrl = removeCourseShareCode(
      Uri.parse(
        'https://magic-pinecone.github.io/magic-pinecone-lite?c=Z21EeqHRw&tab=course#',
      ),
    );

    expect(
      cleanUrl.toString(),
      'https://magic-pinecone.github.io/magic-pinecone-lite?tab=course#',
    );
  });

  test(
    'removeCourseShareCode clears the query when c is the only parameter',
    () {
      final cleanUrl = removeCourseShareCode(
        Uri.parse(
          'https://magic-pinecone.github.io/magic-pinecone-lite?c=Z21EeqHRw#',
        ),
      );

      expect(
        cleanUrl.toString(),
        'https://magic-pinecone.github.io/magic-pinecone-lite#',
      );
    },
  );
}
