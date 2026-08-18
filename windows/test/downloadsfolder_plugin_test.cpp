#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>
#include <variant>

#include "downloadsfolder_plugin.h"

namespace downloadsfolder {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

// The Windows side of this plugin currently has no native method handlers —
// the Dart side handles the desktop platforms directly via Process.run. The
// plugin still has to be registrable and respond to unknown methods with
// NotImplemented so the channel doesn't hang.
TEST(DownloadsfolderPlugin, UnknownMethodReturnsNotImplemented) {
  DownloadsfolderPlugin plugin;
  bool not_implemented_called = false;
  bool success_called = false;
  bool error_called = false;

  plugin.HandleMethodCall(
      MethodCall("someUnknownMethod", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&success_called](const EncodableValue*) { success_called = true; },
          [&error_called](const std::string&, const std::string&,
                          const EncodableValue*) { error_called = true; },
          [&not_implemented_called]() { not_implemented_called = true; }));

  EXPECT_TRUE(not_implemented_called);
  EXPECT_FALSE(success_called);
  EXPECT_FALSE(error_called);
}

}  // namespace test
}  // namespace downloadsfolder
