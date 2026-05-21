package com.oodrive.downloadsfolder

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

/*
 * Unit tests for the Kotlin side of this plugin.
 *
 * Run from the example app's android folder with:
 *   ./gradlew testDebugUnitTest
 */
internal class DownloadsfolderPluginTest {
    @Test
    fun onMethodCall_unknownMethod_returnsNotImplemented() {
        val plugin = DownloadsfolderPlugin()

        val call = MethodCall("someUnknownMethod", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).notImplemented()
    }

    @Test
    fun onMethodCall_getCurrentSdkVersion_returnsBuildVersionSdkInt() {
        val plugin = DownloadsfolderPlugin()

        val call = MethodCall("getCurrentSdkVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success(android.os.Build.VERSION.SDK_INT)
    }
}
