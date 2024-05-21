# Flutter Download Folder Plugin

A Flutter plugin for retrieving the path to the downloads folder and performing operations related to file downloads on different platforms.

## Support
|             | Android | iOS     | Windows |  macOS  |  Linux  |
|-------------|---------|---------|---------|---------|---------| 
| **Support** | SDK 20+ | iOS 12+ |   ✅   |    ✅   |   ✅   |

## How it works?
The Flutter Download Folder plugin provides a simple interface to interact with the downloads folder on various platforms. Here's a brief overview of how the main functionalities work:

##### Get Download Directory Path:
The getDownloadDirectoryPath function uses platform-specific channels to retrieve the path to the downloads folder based on the current platform.
##### Copy File into Download Folder 
The copyFileIntoDownloadFolder function allows you to copy a file into the downloads folder with a specified file name. It ensures a unique name to avoid overwriting existing files.
##### Open Download Folder 
The openDownloadFolder function opens the download folder on the device's file system. The implementation varies based on the platform, using platform-specific channels for Android and iOS, and retrieving the path to the downloads folder for macOS and Windows.


## Installation

To use this plugin, add `downloadsfolder` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  downloadsfolder: ^1.1.0
```  

## Setup
##### Android
* The copyFileIntoDownloadFolder method uses a workaround on Android 29 and higher to avoid using MANAGE_EXTERNAL_STORAGE.
  * On Android devices with API 29 and higher, the method saves the file using MediaStore to bypass restrictions.
  * On Android devices with API 28 and lower, ensure that you have added the `WRITE_EXTERNAL_STORAGE` permission to your AndroidManifest.xml file under the `<application>` element.

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
```

##### iOS
* To enable the `openDownloadFolder` function on iOS, ensure that you have added the following key-value pair to your `Info.plist` file:
```xml
<key>UISupportsDocumentBrowser</key>  
<true/>
```

##### macOS

Go to your project folder, macOS/Runner/DebugProfile.entitlements

> For release you need to open 'YOUR_PROJECT_NAME'Profile.entitlements

and add the following key:

```xml
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

## Usage

##### Get Download Directory Path

```dart
import 'package:downloadsfolder/downloadsfolder.dart';

void main() async {
  try {
    Directory downloadDirectory = await getDownloadDirectory();

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
  String filePath = '/path/to/source/file.txt';
  String fileName = 'copied_file.txt';

  bool? success = await copyFileIntoDownloadFolder(filePath, fileName);
  if (success == true) {
    print('File copied successfully.');
  } else {
    print('Failed to copy file.');
  }
}
 ```
 
##### Open Download Folder

```dart
import 'package:downloadsfolder/downloadsfolder.dart';

void main() async {
  bool success = await openDownloadFolder();
  if (success) {
    print('Download folder opened successfully.');
  } else {
    print('Failed to open download folder.');
  }
}
 ```






