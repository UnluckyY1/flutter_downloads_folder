# Flutter Download Folder Plugin

A Flutter plugin for retrieving the path to the downloads folder and performing operations related to file downloads on different platforms.

## Support
|             | Android | iOS     | Windows |  macOS  |  Linux  |
|-------------|---------|---------|---------|---------|---------|
| **Support** | SDK 19+ | iOS 12+ |   ✅   |    ✅   |   ✅   |

## How it works?
The Flutter Download Folder plugin provides a simple interface to interact with the downloads folder on various platforms. Here's a brief overview of how the main functionalities work:

##### Get Download Directory
`getDownloadDirectory()` returns a `Directory` pointing at the platform's downloads location. On Android this is `Environment.DIRECTORY_DOWNLOADS`; on iOS it is the app's documents directory; on the desktop platforms it is the OS-provided downloads folder.

##### Copy File into Download Folder
`copyFileIntoDownloadFolder(...)` copies a file into the downloads folder, ensuring a unique name to avoid overwriting existing files. Optional knobs:
- `subDirectoryPath` — drop the file into a sub-folder of Downloads (e.g. `"Reports"`); missing intermediate directories are created automatically.
- `openAfterSave` — when `true`, the saved file is opened in the OS default viewer immediately after the copy.

On Android 10+ (API 29+) the file is saved via `MediaStore` so the plugin does not require `MANAGE_EXTERNAL_STORAGE`. It returns a `SavedDownload?` exposing both the on-disk `file` and (on Android 10+ only) the `MediaStore` `contentUri`; see the scoped-storage note below. Returns `null` if the save failed.

##### Open Download Folder
`openDownloadFolder()` opens the download folder in the system file browser. On Android and iOS this goes through a platform channel; on Windows/macOS/Linux it shells out to the appropriate native command.


## Installation

To use this plugin, add `downloadsfolder` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  downloadsfolder: ^2.0.0-pre.2
```

## Setup
##### Android
* The `copyFileIntoDownloadFolder` method uses a workaround on Android 29 and higher to avoid using `MANAGE_EXTERNAL_STORAGE`.
  * On Android devices with API 29 and higher, the method saves the file using `MediaStore` to bypass restrictions.
  * On Android devices with API 28 and lower, ensure that you have added the `WRITE_EXTERNAL_STORAGE` permission to your `AndroidManifest.xml` file under the `<application>` element.

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
```

##### iOS
* To enable the `openDownloadFolder` function on iOS, you must add the `UISupportsDocumentBrowser` key to your `Info.plist`. Without it, iOS will refuse to resolve the `shareddocuments://` URL the plugin opens and `openDownloadFolder` will return `false`.
```xml
<key>UISupportsDocumentBrowser</key>
<true/>
```

##### macOS

Go to your project folder, `macOS/Runner/DebugProfile.entitlements`

> For release you need to open `'YOUR_PROJECT_NAME'Profile.entitlements`

and add the following key:

```xml
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

## Usage

##### Get Download Directory

```dart
import 'package:downloadsfolder/downloadsfolder.dart';

void main() async {
  try {
    final Directory downloadDirectory = await getDownloadDirectory();
    print('Downloads folder path: ${downloadDirectory.path}');
  } catch (e) {
    print('Failed to retrieve downloads folder path $e');
  }
}
```

##### Copy File into Download Folder
```dart
import 'package:downloadsfolder/downloadsfolder.dart';

void main() async {
  final String filePath = '/path/to/source/file.txt';
  final String fileName = 'copied_file.txt';

  final SavedDownload? saved = await copyFileIntoDownloadFolder(
    filePath,
    fileName,
    subDirectoryPath: 'Reports', // optional — saves under /Download/Reports
    openAfterSave: true,         // optional — pops the file in the OS default viewer
  );
  if (saved != null) {
    print('File saved at: ${saved.file.path}');
    if (saved.contentUri != null) {
      // Android 10+: use this URI for read/share/intent work.
      print('MediaStore URI: ${saved.contentUri}');
    }
  } else {
    print('Failed to copy file.');
  }
}
```

> **Android 10+ note (scoped storage).** The `SavedDownload.file` path is real
> — the file genuinely lives at that location and any file-manager app can
> see it. However, due to Android's scoped storage rules, your own app
> generally **cannot** read or write that path back via plain `dart:io` once
> the save is complete. Use `SavedDownload.contentUri` for any subsequent
> work (sharing through `share_plus`, opening with an `ACTION_VIEW`
> intent, reading bytes via `ContentResolver`, etc.). On Android < 10,
> iOS, and the desktop platforms, `file` is directly usable with `dart:io`
> and `contentUri` is `null`.

##### Open Download Folder

```dart
import 'package:downloadsfolder/downloadsfolder.dart';

void main() async {
  final bool success = await openDownloadFolder();
  if (success) {
    print('Download folder opened successfully.');
  } else {
    print('Failed to open download folder.');
  }
}
```
