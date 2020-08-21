// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "api_emu.h"
#include "counter.h"

using namespace emu;

static Dart_Handle HandleError(Dart_Handle handle) {
  if (Dart_IsError(handle)) {
    Dart_PropagateError(handle);
  }
  return handle;
}

static void ApiEmu_Nop(Dart_NativeArguments args) {
  // Do nothing.
}

template <typename T>
T* Self(Dart_NativeArguments args) {
  intptr_t ptr;
  HandleError(Dart_GetNativeReceiver(args, &ptr));
  return reinterpret_cast<T*>(ptr);
}

static void ApiEmu_Counter_Allocate(Dart_NativeArguments args) {
  auto counter = new Counter();
  Dart_Handle result =
      HandleError(__api_emu->Dart_NewObject0("Counter", "_construct"));
  HandleError(__api_emu->Dart_SetPeer(result, reinterpret_cast<intptr_t>(counter)));
  Dart_AttachFinalizer(result, counter, sizeof(Counter),
                       [](void* peer) { delete static_cast<Counter*>(peer); });
  Dart_SetReturnValue(args, result);
}

static void ApiEmu_Counter_GetValue(Dart_NativeArguments args) {
  auto self = Self<Counter>(args);
  Dart_SetReturnValue(args, HandleError(Dart_NewInteger(self->value())));
}

static void ApiEmu_Counter_Increment(Dart_NativeArguments args) {
  auto self = Self<Counter>(args);
  int64_t value;
  HandleError(Dart_GetNativeIntegerArgument(args, 1, &value));
  self->increment(value);
}

struct FunctionLookup {
  const char* name;
  Dart_NativeFunctionTrampoline function;
};

extern "C" FunctionLookup CounterLib_functions[] = {
  {"ApiEmu_Nop", TRAMPOLINE_TO(0, ApiEmu_Nop)},
  {"ApiEmu_Counter_Allocate", TRAMPOLINE_TO(0, ApiEmu_Counter_Allocate)},
  {"ApiEmu_Counter_GetValue", TRAMPOLINE_TO(1, ApiEmu_Counter_GetValue)},
  {"ApiEmu_Counter_Increment", TRAMPOLINE_TO(2, ApiEmu_Counter_Increment)},
  {nullptr, nullptr},
};