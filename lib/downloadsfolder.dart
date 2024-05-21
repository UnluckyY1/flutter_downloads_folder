import 'dart:io';

import 'downloadsfolder_platform_interface.dart';
export 'src/file_extension.dart';
export 'package:path/path.dart';

/// Gets the path to the external storage directory for downloads based on the platform.
///
/// return A [Future] that completes with a [String] representing the path to the downloads directory.
///         Returns `null` if the path retrieval fails or is not applicable on the current platform.
///
/// throws Exception If an error occurs during the path retrieval process.
///
///
/// - On **Android**, this method uses the platform-specific channel to invoke a native method
///   ('getExternalStoragePublicDirectory')
///  and retrieves the path to the external storage downloads directory
///  based on the specified folder type [_androidDownloadsFolderType].
///
/// - On **iOS**, the method returns the Directory to the ApplicationDocumentsDirectory.
///
/// - On **macOS**, the method returns the Directory to the Downloads directory.
///
/// - On **Windows**, the method uses the Windows-specific path provider to retrieve the Directory to the Downloads directory.
Future<Directory> getDownloadDirectory() =>
    DownloadsfolderPlatform.instance.getDownloadFolder();

/// Copies the file to the download folder with the specified file name
/// and ensures a unique name to avoid overwriting existing files.
///
/// - **filePath** The path to the source file that needs to be copied.
///
///  - **fileName** The name for the copied file in the download folder.
///
///  - **file** (Optional) The [File] object representing the source file.
///  If not provided, a [File] object will be created from [filePath].
///
///  - **desiredExtension** (Optional) The desired file extension for the copied file.
///                         If not provided, the extension will be derived from the source file's path.
///
/// return A [Future] that completes with a [bool] value indicating whether the file copy operation was successful or not.
///         Returns `true` if successful, otherwise returns `false`.
///
/// throws Exception If an error occurs during the file copy operation.
///
/// **remarks:**
/// This method checks the Android SDK version and utilizes a workaround to avoid using `MANAGE_EXTERNAL_STORAGE`
/// on Android 29 and higher.
/// For devices with Android API 29 and higher, the method uses the platform-specific channel
/// to invoke a native method ('saveFileUsingMediaStore')
/// and saves the file using `MediaStore` to bypass the restriction.
///
/// On devices with Android versions below 29, the method gets the path to the download folder
/// and copies the file using the `copyTo` method.
/// If the destination file already exists, a unique name is generated
/// by appending a suffix in the form of '_(copyNumber)' to the file name.
/// The copy operation is retried until a unique name is found.
Future<bool?> copyFileIntoDownloadFolder(String filePath, String fileName,
        {File? file, String? desiredExtension}) =>
    DownloadsfolderPlatform.instance.copyFileIntoDownloadFolder(
        filePath, fileName,
        file: file, desiredExtension: desiredExtension);

/// Opens the download folder on the device's file system.
///
/// return A [Future] that completes with a [bool] value indicating whether
/// the operation to open the download folder was successful or not.
///         Returns `true` if successful, otherwise returns `false`.
///
///
/// - On **Android** and **iOS**, this method uses the platform-specific channel
///   to invoke a native method ('openDownloadFolder')
/// to open the download folder directly, providing a seamless user experience.
//
//
/// - On other platforms (e.g., **macOS**, **Windows**), the method retrieves the path to the download folder
///   using the [getDownloadFolder] method,
/// and attempts to launch the file explorer
/// or file manager to open the specified folder using the [launchUrl] function.
///
/// Note: The success of opening the download folder may depend on the availability
/// and configuration of the file explorer or file manager on the device.
Future<bool> openDownloadFolder() =>
    DownloadsfolderPlatform.instance.openDownloadFolder();
