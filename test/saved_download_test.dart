import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedDownload', () {
    test('holds the file path and content uri it was constructed with', () {
      final file = File('/tmp/example/report.pdf');
      final uri = Uri.parse('content://media/external/downloads/42');
      final saved = SavedDownload(file: file, contentUri: uri);

      expect(saved.file.path, '/tmp/example/report.pdf');
      expect(saved.contentUri, uri);
    });

    test('contentUri defaults to null', () {
      final saved = SavedDownload(file: File('/tmp/example.txt'));
      expect(saved.contentUri, isNull);
    });

    test('toString includes the path and the uri', () {
      final saved = SavedDownload(
        file: File('/downloads/foo.bin'),
        contentUri: Uri.parse('content://media/external/downloads/7'),
      );
      final s = saved.toString();
      expect(s, contains('/downloads/foo.bin'));
      expect(s, contains('content://media/external/downloads/7'));
    });
  });
}
