## [2.0.0-pre.2]
#### Breaking Changes
- **`copyFileIntoDownloadFolder` now returns `Future<SavedDownload?>`** instead of `Future<File?>`. `SavedDownload` exposes both `file` (the on-disk path) and `contentUri` (the Android `MediaStore` `content://` URI on Android 10+, `null` elsewhere). Use `contentUri` for any read / share / intent work on Android 10+ — scoped storage prevents raw `dart:io` access to `file.path` from the calling app even though the file exists. **Migration:** replace `saved.path` with `saved.file.path`.
- **Minimum Flutter SDK bumped to 3.44.0** (Dart `^3.12.0`). Required for the Android Built-in Kotlin migration.
- **Android plugin migrated to Built-in Kotlin.** The plugin no longer applies the Kotlin Gradle Plugin (`kotlin-android`). Consumer apps that have not yet migrated to Built-in Kotlin should follow https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers.
- **iOS plugin now ships a Swift Package Manager manifest** at `ios/downloadsfolder/Package.swift`. The CocoaPods podspec is preserved for apps that have not yet adopted SPM.
- **macOS plugin now ships a Swift Package Manager manifest** at `macos/downloadsfolder/Package.swift`. The CocoaPods podspec is preserved for apps that have not yet adopted SPM.

#### New Features
- **`openAfterSave` parameter on `copyFileIntoDownloadFolder`.** When `true`, the saved file is immediately opened in the OS default viewer (`ACTION_VIEW` on Android, `open` / `xdg-open` / `cmd /c start` on the desktop platforms).

#### Bug Fixes
- **iOS `openDownloadFolder` no longer hangs.** The Swift handler now invokes the Flutter result callback via `UIApplication.shared.open(_:options:completionHandler:)` so the Dart future resolves to `true`/`false` correctly.
- **Android `copyFileIntoDownloadFolder` no longer throws on Android 10+.** The native MediaStore helper now resolves the on-disk path by querying `DISPLAY_NAME` + `RELATIVE_PATH` (the deprecated `DATA` column returned `null` on R+), includes the file extension in the saved file's display name, and sanitizes the `subDirectoryPath`. The Dart side no longer force-unwraps the platform-channel result.
- **`copyFileIntoDownloadFolder` now correctly creates nested `subDirectoryPath` directories** on the non-MediaStore path (Android < 29, iOS, desktop). `FileTool.copyTo` previously called `Directory.create()` non-recursively and threw `PathNotFoundException` when the immediate parent did not exist.

#### Example app
- Added a subdirectory text field and an "Open file after save" toggle so the new `subDirectoryPath` / `openAfterSave` knobs can be exercised from the UI.

#### Internal
- Dropped the unused `dartx` dependency.
- Documentation updated to reflect the new return type and scoped-storage behaviour.
- Replaced obsolete `getPlatformVersion` Kotlin/Windows/example tests with assertions that match the current plugin surface, and added Dart unit tests covering `SavedDownload`, `FileTool.copyTo` (collision suffixing, sanitization, diacritic stripping, extension handling), and the method-channel layer (channel name, off-Android short-circuit, native call shape, and the non-Android copy branch with a mocked `path_provider`).
- Added a GitHub Actions workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml)) that on every push/PR runs `dart format --set-exit-if-changed`, `flutter analyze`, and `flutter test` for both the plugin and the example, plus an Android APK build with Kotlin Gradle unit tests, an iOS simulator build, and a macOS build.
- Podspec metadata corrected (homepage, summary, author, version); iOS platform aligned with README at `12.0`.

## [2.0.0-pre.1]
#### Breaking Changes
- **`copyFileIntoDownloadFolder` Return Type**
  - Changed return type from `boolean` to `File` object ([#11](https://github.com/UnluckyY1/flutter_downloads_folder/issues/11))
  - **Migration Required:** Update code to handle the returned `File` instead of boolean checks

#### New Features
- **Subdirectory Support**
  - Added `subDirectoryPath` parameter to `copyFileIntoDownloadFolder` ([#9](https://github.com/UnluckyY1/flutter_downloads_folder/issues/9))


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

