import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FileTool.copyTo', () {
    late Directory tempDir;
    late Directory destDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('downloadsfolder_test_');
      destDir = Directory(p.join(tempDir.path, 'downloads'));
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<File> writeSource(String name, String content) async {
      final source = File(p.join(tempDir.path, name));
      await source.writeAsString(content);
      return source;
    }

    test('creates the destination directory if it does not exist', () async {
      final source = await writeSource('source.txt', 'hello');
      expect(destDir.existsSync(), isFalse);

      final copy = await source.copyTo(destDir.path, 'copied.txt');

      expect(destDir.existsSync(), isTrue);
      expect(copy.existsSync(), isTrue);
      expect(await copy.readAsString(), 'hello');
    });

    test('appends desiredExtension when missing', () async {
      final source = await writeSource('source.bin', 'x');
      final copy = await source.copyTo(
        destDir.path,
        'noext',
        desiredExtension: 'bin',
      );
      expect(p.basename(copy.path), 'noext.bin');
    });

    test(
      'does not double-append when fileName already has the extension',
      () async {
        final source = await writeSource('source.bin', 'x');
        final copy = await source.copyTo(
          destDir.path,
          'already.bin',
          desiredExtension: 'bin',
        );
        expect(p.basename(copy.path), 'already.bin');
      },
    );

    test('extension match is case-insensitive', () async {
      final source = await writeSource('source.bin', 'x');
      final copy = await source.copyTo(
        destDir.path,
        'already.BIN',
        desiredExtension: 'bin',
      );
      expect(p.basename(copy.path), 'already.BIN');
    });

    test('disambiguates against an existing file with a (2) suffix', () async {
      final source = await writeSource('source.txt', 'A');
      await source.copyTo(destDir.path, 'doc.txt');
      final secondCopy = await source.copyTo(destDir.path, 'doc.txt');

      expect(p.basename(secondCopy.path), 'doc(2).txt');
      expect(secondCopy.existsSync(), isTrue);
    });

    test('continues bumping the suffix until a free slot opens up', () async {
      final source = await writeSource('source.txt', 'A');
      await source.copyTo(destDir.path, 'doc.txt');
      await source.copyTo(destDir.path, 'doc.txt');
      final thirdCopy = await source.copyTo(destDir.path, 'doc.txt');

      expect(p.basename(thirdCopy.path), 'doc(3).txt');
    });

    test('strips diacritics from the file name', () async {
      final source = await writeSource('source.txt', 'A');
      final copy = await source.copyTo(destDir.path, 'rapportéàù.txt');
      expect(p.basename(copy.path), 'rapporteau.txt');
    });

    test('replaces unsafe characters with underscores', () async {
      final source = await writeSource('source.txt', 'A');
      final copy = await source.copyTo(
        destDir.path,
        'weird/name*with?stuff.txt',
      );
      // Slashes / asterisks / question marks are not in the allowed set.
      expect(p.basename(copy.path), 'weird_name_with_stuff.txt');
    });

    test(
      'falls back to a timestamp name when the sanitized name is empty',
      () async {
        final source = await writeSource('source.txt', 'A');
        final copy = await source.copyTo(
          destDir.path,
          '',
          desiredExtension: 'txt',
        );
        // The fallback name is microsecondsSinceEpoch — only digits, then .txt.
        final base = p.basenameWithoutExtension(copy.path);
        expect(base, matches(RegExp(r'^\d+$')));
        expect(p.extension(copy.path), '.txt');
      },
    );

    test('throws when folderPath is empty', () async {
      final source = await writeSource('source.txt', 'A');
      expect(() => source.copyTo('', 'foo.txt'), throwsException);
    });
  });
}
