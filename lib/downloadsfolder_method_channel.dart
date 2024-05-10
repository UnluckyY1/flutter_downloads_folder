import 'dart:io';

import 'package:downloadsfolder/src/file_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'downloadsfolder_platform_interface.dart';

import 'package:path_provider/path_provider.dart' as path;
import 'package:path_provider_windows/path_provider_windows.dart'
    as path_provider_windows;
import 'package:path_provider_linux/path_provider_linux.dart'
    as path_provider_linux;

/// An implementation of [DownloadsfolderPlatform] that uses method channels.
class MethodChannelDownloadsfolder extends DownloadsfolderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('downloadsfolder');
  final _androidDownloadsFolderType = 'Download';

  @override
  Future<Directory> getDownloadFolder() async {
    try {
      String? downloadPath = '';
      switch (Platform.operatingSystem) {
        case 'android':
          // Get the external storage downloads directory path on Android using the platform-specific channel.
          downloadPath = await methodChannel.invokeMethod<String>(
            'getExternalStoragePublicDirectory',
            {'type': _androidDownloadsFolderType},
          );
          break;
        case 'ios':
          // Get the ApplicationDocumentsDirectory path for iOS.
          downloadPath = (await path.getApplicationDocumentsDirectory()).path;
          break;
        case 'macos':
          // Get the Downloads directory path for MacOS.
          downloadPath = (await path.getDownloadsDirectory())?.path;
          break;
        case 'windows':
          // Get the Downloads directory path for Windows using the Windows-specific path provider.
          downloadPath = await path_provider_windows.PathProviderWindows()
              .getDownloadsPath();
          break;
        case 'linux':
          downloadPath =
              await path_provider_linux.PathProviderLinux().getDownloadsPath();
          break;

        default:
          throw PlatformException(
            code: 'DOWNLOAD_FOLDER_PATH_ERROR',
            message: 'Failed to retrieve download folder path.',
          );
      }

      if (downloadPath != null) {
        return Directory(downloadPath);
      } else {
        throw PlatformException(
          code: 'DOWNLOAD_FOLDER_PATH_ERROR',
          message: 'Failed to retrieve download folder path.',
        );
      }
    } on PlatformException catch (_) {
      rethrow;
    } catch (e) {
      throw PlatformException(
        code: 'DOWNLOAD_FOLDER_PATH_ERROR',
        message: 'Failed to retrieve download folder path: $e',
      );
    }
  }

  Future<int> _getCurrentSdkVersion() async {
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

  @override
  Future<bool?> copyFileIntoDownloadFolder(String filePath, String fileName,
      {File? file, String? desiredExtension}) async {
    // Determine the Android SDK version (if it's an Android device).
    final androidSdkVersion =
        Platform.isAndroid ? await _getCurrentSdkVersion() : 0;

    if (Platform.isAndroid && androidSdkVersion < 29 || Platform.isIOS) {
      final bool status = await Permission.storage.isGranted;
      if (!status) await Permission.storage.request();
      if (!await Permission.storage.isGranted) {
        return false;
      }
    }

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
        desiredExtension: desiredExtension);

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
    final downloadPath = Platform.isMacOS
        ? 'file://${downloadDirectory.path}'
        : downloadDirectory.path;

    return launchUrl(Uri.parse(downloadPath));
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
}
