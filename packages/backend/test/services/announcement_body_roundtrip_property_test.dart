// Feature: mykiz-platform, Property 7: Announcement body round-trip
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 3.3**
///
/// Property 7: Announcement body round-trip
/// For any valid announcement body string (1–5000 characters of plain text),
/// creating an announcement and then retrieving it SHALL return the body
/// exactly as submitted with no transformation or markup interpretation.

/// Generates a random string of [length] characters from a rich character set
/// that includes ASCII, unicode, HTML-like tags, markdown syntax, special
/// characters, and whitespace.
String _generateRichString(int length, int seed) {
  // Character pools that exercise different transformation risks
  const asciiChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
      '0123456789';
  const specialChars = r'!@#$%^&*()_+-=[]{}|;:,.<>?/~`'
      "\"'\\";
  const whitespace = ' \t\n\r';
  const htmlFragments = [
    '<script>alert("xss")</script>',
    '<b>bold</b>',
    '<img src="x" onerror="alert(1)">',
    '&amp;',
    '&lt;',
    '&gt;',
    '&quot;',
    '&#39;',
    '<div class="test">',
    '</div>',
    '<!-- comment -->',
    '<a href="javascript:void(0)">',
  ];
  const markdownFragments = [
    '**bold**',
    '*italic*',
    '# heading',
    '## heading2',
    '[link](http://example.com)',
    '![image](img.png)',
    '```code```',
    '> blockquote',
    '- list item',
    '1. ordered',
    '---',
    '***',
  ];
  const unicodeChars = 'àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ'
      'αβγδεζηθικλμνξοπρστυφχψω'
      '你好世界日本語한국어'
      '🎉🚀💡🔥✨🎯🌍';

  // Combine all character sources
  final allChars = asciiChars + specialChars + whitespace + unicodeChars;

  final buffer = StringBuffer();
  var rng = seed;

  while (buffer.length < length) {
    // Simple pseudo-random number generator (LCG)
    rng = (rng * 1103515245 + 12345) & 0x7fffffff;
    final choice = rng % 100;

    if (choice < 5 && buffer.length + 20 < length) {
      // Insert HTML fragment
      final fragment = htmlFragments[rng % htmlFragments.length];
      if (buffer.length + fragment.length <= length) {
        buffer.write(fragment);
      }
    } else if (choice < 10 && buffer.length + 15 < length) {
      // Insert markdown fragment
      final fragment = markdownFragments[rng % markdownFragments.length];
      if (buffer.length + fragment.length <= length) {
        buffer.write(fragment);
      }
    } else {
      // Insert single character from combined pool
      final charIndex = rng % allChars.length;
      buffer.write(allChars[charIndex]);
    }
  }

  // Trim to exact length (in case fragments pushed us over)
  final result = buffer.toString();
  if (result.length > length) {
    return result.substring(0, length);
  }
  return result;
}

/// Custom generator for valid announcement body strings (1–5000 characters).
extension AnnouncementBodyGenerators on Any {
  /// Generates a valid body length between 1 and 5000.
  Generator<int> get validBodyLength => intInRange(1, 5001);

  /// Generates a seed for the string generator.
  Generator<int> get stringSeed => intInRange(0, 2147483647);
}

void main() {
  group('Property 7: Announcement body round-trip', () {
    Glados2(any.validBodyLength, any.stringSeed, ExploreConfig(numRuns: 100))
        .test(
      'body content is preserved exactly through toJson/fromJson with no '
      'transformation or markup interpretation',
      (length, seed) {
        final body = _generateRichString(length, seed);

        // Create an Announcement with the generated body
        final original = Announcement(
          id: 'test-uuid-12345',
          title: 'Test Announcement',
          body: body,
          authorId: 'author-uuid-67890',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          updatedAt: DateTime.utc(2024, 1, 15, 10, 30),
        );

        // Serialize to JSON (simulates storing/sending)
        final json = original.toJson();

        // Deserialize from JSON (simulates retrieving)
        final restored = Announcement.fromJson(json);

        // The body MUST be exactly the same — no escaping, no HTML
        // interpretation, no markdown rendering, no trimming, no
        // transformation of any kind.
        expect(
          restored.body,
          equals(body),
          reason: 'Body must survive toJson/fromJson round-trip unchanged. '
              'Length: $length, body starts with: '
              '"${body.substring(0, body.length > 30 ? 30 : body.length)}..."',
        );

        // Additional check: the JSON intermediate representation must also
        // contain the body verbatim (no server-side transformation)
        expect(
          json['body'],
          equals(body),
          reason: 'JSON representation must contain body verbatim',
        );
      },
    );
  });
}
