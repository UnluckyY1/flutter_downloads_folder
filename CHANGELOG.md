## [1.2.0]  
- **Breaking Change:**  
  - Removed the dependency on `permission_handler`.  
  - This plugin no longer manages write permissions.  
  - **Action Required:** You must implement write permission handling in your app manually.  
- [Android] Upgraded the required Android Java version to 17. 
- Fixed Flutter 3.27.0 warning for the Linux platform 

## [1.1.1]
- Updated dependencies to the latest versions.
- Restored the Linux platform tag on pub.dev.

## [1.1.0]
- Implemented more concise and maintainable code organization.
- Reduced duplication by introducing helper methods for platform-specific operations.
- Improved error handling with specific error messages.
- Enhanced platform detection for better compatibility.
- Separated concerns for copying files and opening the download folder.
- Utilized asynchronous operations more efficiently for cleaner code.
- Improved consistency in naming conventions and the use of constants.
- Fixed platform-specific issues related to directory retrieval and opening the download folder.
- Fixed error handling to provide more informative error messages.
- Refactored code to adhere to Dart and Flutter best practices.
- Updated dependencies to the latest versions.
- Removed dependencies on path_provider_windows and path_provider_linux for improved simplicity and reduced overhead.

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

