#ifndef FLUTTER_PLUGIN_DOWNLOADSFOLDER_PLUGIN_H_
#define FLUTTER_PLUGIN_DOWNLOADSFOLDER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace downloadsfolder {

class DownloadsfolderPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  DownloadsfolderPlugin();

  virtual ~DownloadsfolderPlugin();

  // Disallow copy and assign.
  DownloadsfolderPlugin(const DownloadsfolderPlugin&) = delete;
  DownloadsfolderPlugin& operator=(const DownloadsfolderPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace downloadsfolder

#endif  // FLUTTER_PLUGIN_DOWNLOADSFOLDER_PLUGIN_H_
