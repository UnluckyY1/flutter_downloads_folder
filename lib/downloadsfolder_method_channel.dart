import 'dart:io';

import 'package:downloadsfolder/src/constants.dart';
import 'package:downloadsfolder/src/file_extension.dart';
import 'package:downloadsfolder/src/saved_download.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'downloadsfolder_platform_interface.dart';

/// An implementation of [DownloadsfolderPlatform] that uses method channels.
class MethodChannelDownloadsfolder extends DownloadsfolderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('downloadsfolder');
  final _androidDownloadsFolderType = 'Download';

  @override
  Future<Directory> getDownloadFolder() async {
    final downloadDirectory = await switch (Platform.operatingSystem) {
      androidPlatform => getAndroidDirectoryFromFolderType(
        _androidDownloadsFolderType,
      ),
      iosPlatform => getApplicationDocumentsDirectory(),
      macOsPlatform ||
      windowsPlatform ||
      linuxPlatform => getDownloadsDirectory(),
      _ => Future.error(
        PlatformException(
          code: 'DOWNLOAD_FOLDER_PATH_ERROR',
          message: 'Platform is not supported.',
        ),
      ),
    };

    if (downloadDirectory != null) {
      return downloadDirectory;
    } else {
      throw PlatformException(
        code: 'DOWNLOAD_FOLDER_PATH_ERROR',
        message: 'Failed to retrieve download folder path.',
      );
    }
  }

  @override
  Future<int> getCurrentAndroidSdkVersion() async {
    try {
      final sdkVersion = Platform.isAndroid
          ? (await methodChannel.invokeMethod<int>('getCurrentSdkVersion')) ??
                -1
          : -1;

      return sdkVersion;
    } on PlatformException catch (_) {
      rethrow;
    }
  }

  Future<Directory?> getAndroidDirectoryFromFolderType(
    String folderType,
  ) async {
    final String? directoryPath = await methodChannel.invokeMethod<String>(
      'getExternalStoragePublicDirectory',
      {'type': folderType},
    );

    if (directoryPath == null) {
      return null;
    }

    return Directory(directoryPath);
  }

  @override
  Future<SavedDownload?> copyFileIntoDownloadFolder(
    String filePath,
    String fileName, {
    File? file,
    String? desiredExtension,
    String? subDirectoryPath,
    bool openAfterSave = false,
  }) async {
    final androidSdkVersion = Platform.isAndroid
        ? await getCurrentAndroidSdkVersion()
        : 0;

    final fileToCopy = file ?? File(filePath);

    // Android 10+ goes through MediaStore so we don't need MANAGE_EXTERNAL_STORAGE.
    if (Platform.isAndroid && androidSdkVersion >= 29) {
      final result = await methodChannel
          .invokeMapMethod<String, dynamic>('saveFileUsingMediaStore', {
            'filePath': fileToCopy.path,
            'fileName': p.basenameWithoutExtension(fileName),
            'extension': desiredExtension ?? p.extension(fileToCopy.path),
            'subDirectoryPath': subDirectoryPath,
            'openAfterSave': openAfterSave,
          });
      if (result == null) return null;
      final path = result['path'] as String?;
      if (path == null) return null;
      final uri = result['uri'] as String?;
      return SavedDownload(
        file: File(path),
        contentUri: uri == null ? null : Uri.parse(uri),
      );
    }

    // Legacy Android / all other platforms: plain file copy.
    final folderPath = p.absolute(
      (await getDownloadFolder()).path,
      subDirectoryPath,
    );

    final copied = await fileToCopy.copyTo(
      folderPath,
      fileName,
      desiredExtension: desiredExtension ?? p.extension(fileToCopy.path),
    );

    if (openAfterSave) {
      await _openLocalFile(copied);
    }
    return SavedDownload(file: copied);
  }

  @override
  Future<bool> openDownloadFolder() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Open the download folder directly on Android and iOS using the platform-specific channel.
      final result = await methodChannel.invokeMethod<bool?>(
        'openDownloadFolder',
      );
      return result ?? false;
    }

    // For other platforms, retrieve the download folder path and attempt to launch the file explorer or file manager.
    final downloadDirectory = await getDownloadFolder();
    final downloadPath = Platform.isMacOS || Platform.isLinux
        ? 'file://${downloadDirectory.path}'
        : downloadDirectory.path;

    return _openDesktopFolder(downloadPath);
  }

  Future<bool> _openDesktopFolder(String folderPath) async {
    final result = await switch (Platform.operatingSystem) {
      windowsPlatform => Process.run(windowsExplorerCommand, [folderPath]),
      macOsPlatform => Process.run(macOSOpenCommand, [folderPath]),
      linuxPlatform => Process.run(linuxOpenCommand, [folderPath]),
      _ => throw PlatformException(
        code: 'OPEN_FOLDER_ERROR',
        message: 'Platform is not supported',
      ),
    };

    return result.exitCode == 0;
  }

  /// Opens a local file with the OS default viewer. Used by the legacy
  /// `openAfterSave: true` branch (Android < 29, iOS, desktop).
  Future<bool> _openLocalFile(File file) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Android < 29 case: file is directly accessible. Use ACTION_VIEW
      // via the platform-channel `openFile` method.
      try {
        final ok = await methodChannel.invokeMethod<bool>('openFile', {
          'uri': 'file://${file.path}',
          'mimeType': null,
        });
        return ok ?? false;
      } catch (_) {
        return false;
      }
    }
    final result = await switch (Platform.operatingSystem) {
      windowsPlatform => Process.run('cmd', ['/c', 'start', '""', file.path]),
      macOsPlatform => Process.run(macOSOpenCommand, [file.path]),
      linuxPlatform => Process.run(linuxOpenCommand, [file.path]),
      _ => Future<ProcessResult>.value(ProcessResult(0, 1, '', '')),
    };
    return result.exitCode == 0;
  }
}
