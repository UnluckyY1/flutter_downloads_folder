import 'dart:io';

import 'downloadsfolder_platform_interface.dart';
import 'src/saved_download.dart';

export 'src/file_extension.dart';
export 'src/saved_download.dart';
export 'package:path/path.dart';

/// Returns the platform-specific downloads directory.
///
/// - **Android**: the public `Environment.DIRECTORY_DOWNLOADS` directory,
///   resolved through a platform-channel call to
///   `Environment.getExternalStoragePublicDirectory`.
/// - **iOS**: the app's documents directory.
/// - **macOS**, **Windows**, **Linux**: the OS-provided downloads directory
///   returned by `path_provider`.
///
/// Throws a [PlatformException] if the directory cannot be resolved or the
/// current platform is not supported.
Future<Directory> getDownloadDirectory() =>
    DownloadsfolderPlatform.instance.getDownloadFolder();

/// Copies the file at [filePath] into the platform's downloads folder, using
/// a unique destination name so existing files are never overwritten.
///
/// Parameters:
/// - **filePath**: path to the source file.
/// - **fileName**: desired filename (without folders) for the copy.
/// - **file**: optional pre-resolved [File] for the source. Defaults to
///   `File(filePath)`.
/// - **desiredExtension**: optional extension override (`.pdf`, `pdf`, etc.).
/// - **subDirectoryPath**: optional sub-folder under Downloads (e.g.
///   `"Reports"`).
/// - **openAfterSave**: when true, immediately opens the saved file in the
///   OS default viewer (via `ACTION_VIEW` on Android, `open`/`xdg-open`/
///   `cmd /c start` on the desktop platforms). Default `false`.
///
/// Returns a [SavedDownload] describing the saved file, or `null` if the
/// save did not produce a resolvable path. Throws if the underlying I/O or
/// platform channel call fails.
///
/// Platform behaviour:
/// - **Android 10+** (API 29+): the file is saved via `MediaStore` so the
///   plugin does **not** require `MANAGE_EXTERNAL_STORAGE`. Because of
///   scoped storage the calling app generally **cannot perform raw
///   `dart:io` I/O on the returned `File` path** even though the file
///   exists. Use `SavedDownload.contentUri` (a `content://` URI) for any
///   read / share / `Intent.ACTION_VIEW` work from the calling app. The
///   `File.path` is still useful to display where the file landed.
/// - **Android < 29**, **iOS**, **macOS**, **Windows**, **Linux**: the file
///   is a normal copy; `SavedDownload.file` is directly usable with
///   `dart:io` and `SavedDownload.contentUri` is `null`.
Future<SavedDownload?> copyFileIntoDownloadFolder(
  String filePath,
  String fileName, {
  File? file,
  String? desiredExtension,
  String? subDirectoryPath,
  bool openAfterSave = false,
}) => DownloadsfolderPlatform.instance.copyFileIntoDownloadFolder(
  filePath,
  fileName,
  file: file,
  desiredExtension: desiredExtension,
  subDirectoryPath: subDirectoryPath,
  openAfterSave: openAfterSave,
);

/// Opens the downloads folder in the system file browser.
///
/// - On **Android** and **iOS**, this method uses the platform channel to
///   open the system file manager / Files app at the downloads location.
/// - On **macOS**, **Windows**, and **Linux**, the plugin shells out to the
///   appropriate native command (`open`, `explorer.exe`, `xdg-open`).
///
/// Returns `true` if the folder was opened successfully, `false` otherwise.
/// Success on iOS additionally requires the `UISupportsDocumentBrowser` key
/// in `Info.plist`.
Future<bool> openDownloadFolder() =>
    DownloadsfolderPlatform.instance.openDownloadFolder();

/// Returns the current Android SDK integer (`Build.VERSION.SDK_INT`).
///
/// Returns `-1` on every non-Android platform.
Future<int> getCurrentAndroidSdkVersion() =>
    DownloadsfolderPlatform.instance.getCurrentAndroidSdkVersion();
