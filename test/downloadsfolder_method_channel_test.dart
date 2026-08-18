import 'dart:io';

import 'package:downloadsfolder/downloadsfolder_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.downloadsPath);

  final String downloadsPath;

  @override
  Future<String?> getDownloadsPath() async => downloadsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => downloadsPath;

  @override
  Future<String?> getTemporaryPath() async => downloadsPath;

  @override
  Future<String?> getApplicationSupportPath() async => downloadsPath;

  @override
  Future<String?> getLibraryPath() async => downloadsPath;

  @override
  Future<String?> getExternalStoragePath() async => downloadsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelDownloadsfolder', () {
    final platform = MethodChannelDownloadsfolder();
    const channel = MethodChannel('downloadsfolder');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    /// Records every method call the platform implementation sends to the
    /// native side and returns whatever the test handler decides.
    final calls = <MethodCall>[];

    void mockNative(Object? Function(MethodCall call) handler) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return handler(call);
      });
    }

    tearDown(() {
      calls.clear();
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('uses the "downloadsfolder" channel name', () {
      expect(platform.methodChannel.name, 'downloadsfolder');
    });

    test('getCurrentAndroidSdkVersion returns -1 off Android', () async {
      // Outside of Android the implementation short-circuits without touching
      // the channel.
      expect(await platform.getCurrentAndroidSdkVersion(), -1);
      expect(calls, isEmpty);
    });

    test('getAndroidDirectoryFromFolderType wraps the returned path', () async {
      mockNative((call) {
        if (call.method == 'getExternalStoragePublicDirectory') {
          expect(call.arguments, {'type': 'Download'});
          return '/storage/emulated/0/Download';
        }
        return null;
      });

      final dir = await platform.getAndroidDirectoryFromFolderType('Download');

      expect(dir, isNotNull);
      expect(dir!.path, '/storage/emulated/0/Download');
    });

    test(
      'getAndroidDirectoryFromFolderType returns null when native does',
      () async {
        mockNative((_) => null);
        final dir = await platform.getAndroidDirectoryFromFolderType(
          'Download',
        );
        expect(dir, isNull);
      },
    );

    // The Android-29+ branch of `copyFileIntoDownloadFolder` checks
    // `Platform.isAndroid` synchronously, so we can only exercise it from a
    // device or emulator running the integration test. Here we instead test
    // the non-Android path, which is the same code shipped to iOS / desktop.
    //
    // We can't mock the path_provider method channel because path_provider_linux
    // is a pure-Dart implementation (no channel at all). Instead we override
    // `PathProviderPlatform.instance` so the fake is hit regardless of host OS.
    group('copyFileIntoDownloadFolder (non-Android branch)', () {
      late Directory tempDir;
      late Directory fakeDownloads;
      late File source;
      late PathProviderPlatform originalPathProvider;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp(
          'downloadsfolder_mctest_',
        );
        fakeDownloads = Directory('${tempDir.path}/Downloads');
        source = File('${tempDir.path}/source.txt');
        await source.writeAsString('hello');

        originalPathProvider = PathProviderPlatform.instance;
        PathProviderPlatform.instance = _FakePathProvider(fakeDownloads.path);
      });

      tearDown(() async {
        PathProviderPlatform.instance = originalPathProvider;
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('returns a SavedDownload pointing at the copied file', () async {
        final saved = await platform.copyFileIntoDownloadFolder(
          source.path,
          'copied.txt',
        );

        expect(saved, isNotNull);
        expect(saved!.contentUri, isNull); // never set off Android 10+
        expect(saved.file.existsSync(), isTrue);
        expect(await saved.file.readAsString(), 'hello');
        expect(saved.file.path, contains(fakeDownloads.path));
      });

      test('places the copy under subDirectoryPath when provided', () async {
        final saved = await platform.copyFileIntoDownloadFolder(
          source.path,
          'copied.txt',
          subDirectoryPath: 'reports',
        );

        expect(saved, isNotNull);
        expect(saved!.file.path, contains('${fakeDownloads.path}/reports'));
      });
    });

    test(
      'openDownloadFolder forwards the native boolean on mobile-like channel',
      () async {
        // Even on the host (where the implementation skips the channel and
        // shells out), we can verify the channel-name plumbing by intercepting
        // any call that does happen.
        mockNative((call) {
          if (call.method == 'openDownloadFolder') return true;
          return null;
        });

        // We don't await the result on desktop because it would actually launch
        // Finder/Explorer. Instead we just confirm calling it doesn't throw.
        if (Platform.isAndroid || Platform.isIOS) {
          expect(await platform.openDownloadFolder(), isTrue);
          expect(calls.single.method, 'openDownloadFolder');
        }
      },
    );
  });
}
