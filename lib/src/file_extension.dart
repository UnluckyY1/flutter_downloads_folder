import 'dart:io';

import 'package:dartx/dartx.dart';

import 'package:diacritic/diacritic.dart';
import 'package:path/path.dart';

extension FileTool on File {
  /// Copies the file to the specified folder with the given file name, ensuring a unique name to avoid overwriting existing files.
  ///
  /// - **folderPath:** The path to the destination folder where the file will be copied.
  /// 
  /// - **fileName:** The name for the copied file in the destination folder.
  /// 
  /// - **desiredExtension:** (Optional) The desired file extension for the copied file.
  ///                         If provided, the copied file will have this extension; otherwise, the extension is derived from the original file's name.
  ///
  /// - @return A [Future] that completes with a [File] object representing the copied file in the destination folder.
  ///
  /// - @throws Exception If an error occurs during the file copy operation, or if the destination folder path is not valid.
  ///
  /// - @remarks
  /// This method ensures a unique file name in the destination folder to avoid overwriting existing files.
  /// If a file with the same name already exists, a suffix in the form of '_(copyNumber)' is added to the file name, and the copy operation is retried.
  Future<File> copyTo(String folderPath, String fileName,
      {String? desiredExtension}) async {
    if (folderPath.isNotNullOrEmpty) {
      // Ensure a valid and unique file name in the destination folder.
      String protectedFileName = removeDiacritics(fileName)
          .replaceAll(RegExp('[^A-Za-z0-9\\.\\(\\)\\- ]'), '_');
      if (protectedFileName.isEmpty) {
        protectedFileName = DateTime.now().microsecondsSinceEpoch.toString();
      }

      if (desiredExtension != null &&
          !protectedFileName.toLowerCase().endsWith('.$desiredExtension')) {
        protectedFileName = '$protectedFileName.$desiredExtension';
      }

      String destFilePath = join(folderPath, protectedFileName);
      int copyNumber = 2;

      // If a file with the same name already exists, add a suffix and retry.
      while (await File(destFilePath).exists()) {
        final fileBaseName = basenameWithoutExtension(protectedFileName);
        final fileExtension = extension(protectedFileName);

        destFilePath =
            join(folderPath, '$fileBaseName($copyNumber)$fileExtension');
        copyNumber++;
      }

      // Perform the actual file copy.
      return copy(destFilePath);
    } else {
      throw Exception('Something wrong happened: Cannot save the file');
    }
  }
}
