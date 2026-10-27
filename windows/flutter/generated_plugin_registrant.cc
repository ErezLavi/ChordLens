//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <device_manager/device_manager_plugin.h>
#include <flutter_midi_pro/flutter_midi_pro_plugin_c_api.h>
#include <universal_ble/universal_ble_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DeviceManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DeviceManagerPlugin"));
  FlutterMidiProPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterMidiProPluginCApi"));
  UniversalBlePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UniversalBlePluginCApi"));
}
