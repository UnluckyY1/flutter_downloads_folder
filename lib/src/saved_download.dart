import 'dart:io';

/// The result of [copyFileIntoDownloadFolder].
///
/// Wraps both the saved file's on-disk path and (on Android 10+) the
/// `MediaStore` `content://` URI that should be used for any further I/O,
/// sharing, or system intents.
class SavedDownload {
  /// The file location on disk.
  ///
  /// - On **iOS**, **macOS**, **Windows**, **Linux**, and **Android < 10**,
  ///   the calling app can perform normal `dart:io` I/O against this path
  ///   (read, write, share, delete).
  /// - On **Android 10+** scoped storage prevents raw `dart:io` access for
  ///   most apps even though the file genuinely exists at this path. Use
  ///   [contentUri] when you need to read, share, or open the saved file
  ///   from the calling app. The [file] path remains useful for UI ("Saved
  ///   to /Download/foo.pdf") and for users browsing through a file manager.
  final File file;

  /// The `MediaStore` `content://` URI for the saved file on Android 10+.
  ///
  /// `null` on all other platforms (and on Android < 10, where [file] is
  /// directly usable). When non-null this URI is the only reliable handle
  /// the calling app has for further work — pass it to `share_plus`, an
  /// `Intent`, or a `ContentResolver` to read the bytes back.
  final Uri? contentUri;

  const SavedDownload({required this.file, this.contentUri});

  @override
  String toString() =>
      'SavedDownload(file: ${file.path}, contentUri: $contentUri)';
}
