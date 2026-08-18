package com.oodrive.downloadsfolder

import android.annotation.TargetApi
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.app.DownloadManager
import android.provider.MediaStore
import androidx.annotation.NonNull
import java.io.FileInputStream
import java.io.IOException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** DownloadsfolderPlugin */
class DownloadsfolderPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "downloadsfolder")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getExternalStoragePublicDirectory" -> {
                val type = call.argument<String>("type")
                val directory = Environment.getExternalStoragePublicDirectory(type)
                result.success(directory.toString())
            }

            "saveFileUsingMediaStore" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val filePath = call.argument<String>("filePath")!!
                    val fileName = call.argument<String>("fileName")!!
                    val extension = call.argument<String?>("extension")
                    val subDirectoryPath = call.argument<String?>("subDirectoryPath")
                    val openAfterSave = call.argument<Boolean?>("openAfterSave") ?: false

                    try {
                        val saved = saveFileUsingMediaStore(
                            context, filePath, fileName, extension, subDirectoryPath
                        )
                        if (openAfterSave) {
                            openFile(saved.uri, saved.mimeType)
                        }
                        result.success(
                            mapOf(
                                "path" to saved.path,
                                "uri" to saved.uri.toString(),
                            )
                        )
                    } catch (e: IOException) {
                        e.printStackTrace()
                        result.error("IOException", e.toString(), null)
                    }
                } else {
                    result.error("Old API version", "Requires API level 29 or higher", null)
                }
            }

            "openFile" -> {
                val uriString = call.argument<String>("uri")
                val mimeType = call.argument<String?>("mimeType")
                if (uriString == null) {
                    result.error("ARGUMENT_ERROR", "uri is required", null)
                } else {
                    try {
                        openFile(Uri.parse(uriString), mimeType)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_FILE_ERROR", e.toString(), null)
                    }
                }
            }

            "openDownloadFolder" -> {
                openDownloadFolder(result)
            }

            "getCurrentSdkVersion" -> {
                result.success(Build.VERSION.SDK_INT)
            }

            else -> result.notImplemented()
        }
    }

    private data class SavedMediaStoreFile(
        val path: String,
        val uri: Uri,
        val mimeType: String,
    )

    @TargetApi(Build.VERSION_CODES.Q)
    private fun saveFileUsingMediaStore(
        context: Context,
        sourceFilePath: String,
        fileName: String,
        extension: String?,
        subDirectoryPath: String?
    ): SavedMediaStoreFile {
        val sanitizedSubPath = subDirectoryPath
            ?.trim()
            ?.trim('/')
            ?.takeIf { it.isNotEmpty() }

        val relativePath = if (sanitizedSubPath != null) {
            "${Environment.DIRECTORY_DOWNLOADS}/$sanitizedSubPath"
        } else {
            Environment.DIRECTORY_DOWNLOADS
        }

        val normalizedExtension = extension
            ?.trim()
            ?.removePrefix(".")
            ?.takeIf { it.isNotEmpty() }
        val displayName = if (
            normalizedExtension != null &&
            !fileName.endsWith(".$normalizedExtension", ignoreCase = true)
        ) {
            "$fileName.$normalizedExtension"
        } else {
            fileName
        }

        val mimeType = getMimeTypeFromExtension(normalizedExtension) ?: "application/octet-stream"

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
        }

        val resolver = context.contentResolver
        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI

        val uri = resolver.insert(collection, contentValues)
            ?: throw IOException("Failed to insert file into MediaStore")

        FileInputStream(sourceFilePath).use { input ->
            val output = resolver.openOutputStream(uri)
                ?: throw IOException("Failed to open output stream for MediaStore entry")
            output.use { input.copyTo(it) }
        }

        // Resolve the on-disk path. MediaStore stores Download-collection entries
        // at <ExternalStoragePublicDir>/<RELATIVE_PATH>/<DISPLAY_NAME>; both
        // columns are reliable across API levels, unlike the deprecated DATA
        // column. Re-querying after insert also reflects any collision-avoidance
        // renaming MediaStore performed (e.g. "file (1).pdf").
        var resolvedPath: String? = null
        resolver.query(
            uri,
            arrayOf(
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.RELATIVE_PATH
            ),
            null,
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME)
                val relIndex = cursor.getColumnIndex(MediaStore.MediaColumns.RELATIVE_PATH)
                val storedName = if (nameIndex >= 0) cursor.getString(nameIndex) else null
                val storedRel = if (relIndex >= 0) cursor.getString(relIndex) else null
                val effectiveName = storedName ?: displayName
                val effectiveRel = (storedRel ?: "$relativePath/").trim('/')
                val publicRoot = Environment.getExternalStorageDirectory().absolutePath
                resolvedPath = "$publicRoot/$effectiveRel/$effectiveName"
            }
        }

        if (resolvedPath.isNullOrEmpty()) {
            val publicDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            val parent = if (sanitizedSubPath != null) {
                "${publicDir.absolutePath}/$sanitizedSubPath"
            } else {
                publicDir.absolutePath
            }
            resolvedPath = "$parent/$displayName"
        }

        return SavedMediaStoreFile(path = resolvedPath!!, uri = uri, mimeType = mimeType)
    }

    /**
     * Opens [uri] in the user's default viewer for [mimeType] using ACTION_VIEW.
     * Grants temporary read permission so the receiving app can read the file
     * even though it's owned by us.
     */
    private fun openFile(uri: Uri, mimeType: String?) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType ?: "*/*")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(intent)
    }

    private fun openDownloadFolder(result: Result) {
        try {
            val downloadIntent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(downloadIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("$e", "Unable to open the file manager", "")
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
