import Flutter
import UIKit

public class DownloadsfolderPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "downloadsfolder", binaryMessenger: registrar.messenger())
    let instance = DownloadsfolderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openDownloadFolder":
      openDownloadFolder(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func openDownloadFolder(result: @escaping FlutterResult) {
    let documentsURL = getDocumentsDirectory()
    let sharedDocumentsString = documentsURL.absoluteString
      .replacingOccurrences(of: "file://", with: "shareddocuments://")

    guard let url = URL(string: sharedDocumentsString) else {
      result(FlutterError(
        code: "OPEN_FOLDER_ERROR",
        message: "Failed to construct shareddocuments:// URL",
        details: nil
      ))
      return
    }

    DispatchQueue.main.async {
      UIApplication.shared.open(url, options: [:]) { success in
        result(success)
      }
    }
  }

  private func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
  }
}
