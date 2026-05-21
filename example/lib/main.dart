import 'dart:async';
import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyExample());
}

class MyExample extends StatelessWidget {
  const MyExample({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _downloadsfolderPath;
  File? _pickedFile;

  /// User-controlled save options.
  final TextEditingController _subDirController = TextEditingController();
  bool _openAfterSave = false;

  @override
  void dispose() {
    _subDirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _getDownloadPath,
              child: const Text('Get Download Path'),
            ),
            if (_downloadsfolderPath != null) ...[
              const SizedBox(height: 8),
              Text('Downloads Folder Path: $_downloadsfolderPath'),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickAFile,
              child: const Text('Pick a File'),
            ),
            if (_pickedFile != null) ...[
              const SizedBox(height: 8),
              Text('Picked File Path: ${_pickedFile!.path}'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Save options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _subDirController,
              decoration: const InputDecoration(
                labelText: 'Subdirectory (optional)',
                hintText: 'e.g. "Reports" — leave empty for root of Downloads',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open file after save'),
              subtitle: const Text(
                'Launches the OS default viewer once the copy completes',
              ),
              value: _openAfterSave,
              onChanged: (v) => setState(() => _openAfterSave = v),
            ),
            const SizedBox(height: 8),
            if (_pickedFile != null)
              ElevatedButton(
                onPressed: _saveFile,
                child: const Text('Save Picked File into Downloads Folder'),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openDownloadFolder,
              child: const Text('Show Download Folder'),
            ),
          ],
        ),
      ),
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _getDownloadPath() async {
    Directory downloadsfolderPath;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      downloadsfolderPath = await getDownloadDirectory();
      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      if (!mounted) return;

      setState(() {
        _downloadsfolderPath = downloadsfolderPath.path;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _downloadsfolderPath = 'Failed to get folder path.';
      });
    }
  }

  Future<void> _pickAFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (!mounted) return;

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _pickedFile = file;
      });
    } else {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('No File Has been selected')),
      );
    }
  }

  Future<void> _saveFile() async {
    bool storagePermissionGranted = true;

    final androidSdk = await getCurrentAndroidSdkVersion();

    if (Platform.isAndroid && androidSdk < 33 || Platform.isIOS) {
      storagePermissionGranted = await Permission.storage.isGranted;

      if (!storagePermissionGranted) {
        // Request storage permission
        final status = await Permission.storage.request();
        storagePermissionGranted = status.isGranted;
      }
    }

    if (!storagePermissionGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Failed to copy file. Storage permission is required.'),
        ),
      );
      return;
    }

    final trimmedSubDir = _subDirController.text.trim();
    final subDir = trimmedSubDir.isEmpty ? null : trimmedSubDir;

    final saved = await copyFileIntoDownloadFolder(
      _pickedFile!.path,
      basenameWithoutExtension(_pickedFile!.path),
      desiredExtension: extension(_pickedFile!.path),
      subDirectoryPath: subDir,
      openAfterSave: _openAfterSave,
    );

    if (!mounted) return;

    final snackBody = saved == null
        ? 'Failed to copy file.'
        : 'File saved to: "${saved.file.path}"'
            '${saved.contentUri != null ? '\nMediaStore URI: ${saved.contentUri}' : ''}';

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(snackBody),
        action: saved != null
            ? SnackBarAction(
                label: 'Show Download Folder',
                onPressed: _openDownloadFolder,
              )
            : null,
      ),
    );
  }

  Future<void> _openDownloadFolder() => openDownloadFolder();
}
