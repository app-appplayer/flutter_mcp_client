#include "include/flutter_mcp_client/flutter_mcp_client_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_mcp_client_plugin.h"

void FlutterMcpClientPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_mcp_client::FlutterMcpClientPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
