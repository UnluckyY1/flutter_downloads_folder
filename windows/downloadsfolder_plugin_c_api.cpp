#include "include/downloadsfolder/downloadsfolder_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "downloadsfolder_plugin.h"

void DownloadsfolderPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  downloadsfolder::DownloadsfolderPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
