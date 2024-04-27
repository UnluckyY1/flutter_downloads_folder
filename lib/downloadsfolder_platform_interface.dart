import 'dart:io';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'downloadsfolder_method_channel.dart';

abstract class DownloadsfolderPlatform extends PlatformInterface {
  /// Constructs a DownloadsfolderPlatform.
  DownloadsfolderPlatform() : super(token: _token);

  static final Object _token = Object();

  static DownloadsfolderPlatform _instance = MethodChannelDownloadsfolder();

  /// The default instance of [DownloadsfolderPlatform] to use.
  ///
  /// Defaults to [MethodChannelDownloadsfolder].
  static DownloadsfolderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DownloadsfolderPlatform] when
  /// they register themselves.
  static set instance(DownloadsfolderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Directory> getDownloadFolder() => throw UnimplementedError(
      'getDownloadFolderPath() has not been implemented.');

  Future<bool?> copyFileIntoDownloadFolder(String filePath, String fileName,
          {File? file, String? desiredExtension}) =>
      throw UnimplementedError(
          'copyFileIntoDownloadFolder() has not been implemented.');

  Future<bool> openDownloadFolder() => throw UnimplementedError(
      'openDownloadFolder() has not been implemented.');
}
