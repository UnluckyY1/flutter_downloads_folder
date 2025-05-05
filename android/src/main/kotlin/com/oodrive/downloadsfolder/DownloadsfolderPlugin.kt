package com.oodrive.downloadsfolder

import android.annotation.TargetApi
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.os.storage.StorageManager
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
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
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
                    val subDirectoryPath= call.argument<String?>("subDirectoryPath")

                    try {
                     val fileUri = saveFileUsingMediaStore(context, filePath, fileName, extension, subDirectoryPath)
                     result.success(fileUri)
                    } catch (e: IOException) {
                        e.printStackTrace()
                        result.error("IOException", e.toString(), null)
                    }

                } else {
                    result.error("Old API version", "Requires API level 29 or higher", null)
                }
            }

            "openDownloadFolder" -> {
                openDownloadFolder(result)
            }

            "getCurrentSdkVersion" -> {
                val sdkVersion = getCurrentSdkVersion()
                result.success(sdkVersion)
            }

            else -> result.notImplemented()
        }
    }

    @TargetApi(Build.VERSION_CODES.Q)
    private fun saveFileUsingMediaStore(
        context: Context,
        filePath: String,
        fileName: String,
        extension: String?,
        subDirectoryPath: String? // Optional subdirectory (e.g., "Reports")
    ): String? {
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(
                MediaStore.MediaColumns.MIME_TYPE,
                getMimeTypeFromExtension(extension) ?: "application/octet-stream"
            )
            subDirectoryPath?.let { path ->
                // Format: "Downloads/YourSubdirectory"
                val sanitizedPath = "${Environment.DIRECTORY_DOWNLOADS}/${path
                    .trim()
                    .trimStart('/')
                    .trimEnd('/')}"
                put(MediaStore.MediaColumns.RELATIVE_PATH, sanitizedPath)
            }
        }
    
        val resolver = context.contentResolver
        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
    
        val uri = resolver.insert(collection, contentValues)
            ?: throw IOException("Failed to insert file into MediaStore")
    
        FileInputStream(filePath).use { input ->
            resolver.openOutputStream(uri).use { output ->
                input.copyTo(output!!)
            }
        }
    
           // Attempt to get the path (works only on Android ≤ 9)
    var filePath: String? = null
    resolver.query(uri, arrayOf(MediaStore.MediaColumns.DATA), null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
            filePath = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA))
        }
    }

    return filePath
    }

    /**
     * Opens the download folder on the device using an Intent to launch the file manager or file explorer.
     *
     *
     *
     * This method creates an Intent with the action [DownloadManager.ACTION_VIEW_DOWNLOADS] to open the system's default file manager or file explorer
     * at the location of the downloads directory. The Intent is then started with the [startActivity] method.
     * The success of opening the download folder may depend on the availability and configuration of the file manager on the device.
     *
     * If an exception occurs during the process, the error is communicated back to the Flutter framework using the result's [error] method.
     */
    private fun openDownloadFolder(result: Result) {
        try {
            // Create an Intent to open the system's default file manager or file explorer at the downloads directory.
            val downloadIntent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS)
            downloadIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK

            // Start the Intent to open the file manager and notify Flutter about the success.
            context.startActivity(downloadIntent)
            result.success(true)
        } catch (e: Exception) {
            // If an exception occurs, communicate the error back to Flutter.
            result.error("$e", "Unable to open the file manager", "")
        }
    }

    private fun getCurrentSdkVersion(): Int {
        return Build.VERSION.SDK_INT
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
