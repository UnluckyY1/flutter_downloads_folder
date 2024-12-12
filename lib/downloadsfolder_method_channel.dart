import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:downloadsfolder/src/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'downloadsfolder_platform_interface.dart';

import 'package:path_provider/path_provider.dart';

/// An implementation of [DownloadsfolderPlatform] that uses method channels.
class MethodChannelDownloadsfolder extends DownloadsfolderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('downloadsfolder');
  final _androidDownloadsFolderType = 'Download';

  @override
  Future<Directory> getDownloadFolder() async {
    final downloadDirectory = await switch (Platform.operatingSystem) {
      androidPlatform =>
        getAndroidDirectoryFromFolderType(_androidDownloadsFolderType),
      iosPlatform => getApplicationDocumentsDirectory(),
      macOsPlatform ||
      windowsPlatform ||
      linuxPlatform =>
        getDownloadsDirectory(),
      _ => Future.error(PlatformException(
          code: 'DOWNLOAD_FOLDER_PATH_ERROR',
          message: 'Platform is not supported.',
        )),
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

  Future<int> getCurrentAndroidSdkVersion() async {
    try {
      final int? sdkVersion =
          await methodChannel.invokeMethod('getCurrentSdkVersion');
      if (sdkVersion != null) {
        return sdkVersion;
      } else {
        throw PlatformException(
          code: 'UNKNOWN_SDK_VERSION',
          message: 'Failed to retrieve SDK version.',
        );
      }
    } on PlatformException catch (_) {
      rethrow;
    }
  }

  Future<Directory?> getAndroidDirectoryFromFolderType(
      String folderType) async {
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
  Future<bool?> copyFileIntoDownloadFolder(String filePath, String fileName,
      {File? file, String? desiredExtension}) async {
    // Determine the Android SDK version (if it's an Android device).
    final androidSdkVersion =
        Platform.isAndroid ? await getCurrentAndroidSdkVersion() : 0;

    final fileToCopy = file ?? File(filePath);

    // This is a workaround to avoid using MANAGE_EXTERNAL_STORAGE on Android 29 and higher.
    // Instead, we use MediaStore within the native code to save the file.
    if (Platform.isAndroid && androidSdkVersion >= 29) {
      // Use the platform-specific channel to invoke a method and save a file using MediaStore.
      // 'saveFileUsingMediaStore' can only be used with Android API 29 and higher.
      return _saveFileUsingMediaStore(
          fileToCopy,
          basenameWithoutExtension(fileName),
          desiredExtension ?? extension(fileToCopy.path));
    }
    // Get the path to the download folder.
    final folder = await getDownloadFolder();

    // Copy the file to the download folder with the specified file name and ensures a unique name to avoid overwriting existing files.
    await fileToCopy.copyTo(folder.path, fileName,
        desiredExtension: desiredExtension ?? extension(fileToCopy.path));

    return true;
  }

  @override
  Future<bool> openDownloadFolder() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Open the download folder directly on Android and iOS using the platform-specific channel.
      final result =
          await methodChannel.invokeMethod<bool?>('openDownloadFolder');
      return result ?? false;
    }

    // For other platforms, retrieve the download folder path and attempt to launch the file explorer or file manager.
    final downloadDirectory = await getDownloadFolder();
    final downloadPath = Platform.isMacOS || Platform.isLinux
        ? 'file://${downloadDirectory.path}'
        : downloadDirectory.path;

    return _openDesktopFolder(downloadPath);
  }

  Future<bool?> _saveFileUsingMediaStore(
          File fileToCopy, String fileName, String desiredExtension) =>
      methodChannel.invokeMethod<bool>(
        'saveFileUsingMediaStore',
        {
          'filePath': fileToCopy.path,
          'fileName': fileName,
          'extension': desiredExtension
        },
      );

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
}
