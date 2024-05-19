## [1.1.0-pre-release]
- remove the usage of url_launcher plugin
- Fix (Desktop) Copy the default file extension if desiredExtension is not provided.


## [1.0.1]
- Updates documentation on README.md.
- Fix linux compilation ([#3](https://github.com/UnluckyY1/flutter_downloads_folder/issues/3))
- Fix openDownloadFolder not working on Linux.


## [1.0.0]
- remove the usage of device_info_plus plugin
- **BREAKING** Bump compileSdkVersion to 34 in Gradle buildscripts
- **BREAKING** Change getDownloadFolderPath to getDownloadFolder and have it return a Directory instead of a String?
- FIX openDownloadFolder not working with MacOs
- Update dependencies


## [0.1.1] 
- update dependencies
- update example app

## [0.0.5] - Initial Release
- Released the initial version of the `downloadsfolder` plugin.
- Added functionality to retrieve the path to the downloads folder based on the platform.
- Implemented the ability to copy files into the downloads folder, ensuring unique names to avoid overwriting existing files.
- Provided the option to open the downloads folder on the device's file system.

