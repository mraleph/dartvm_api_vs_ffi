// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "api_emu.h"

#include <cstdarg>
#include <cstdint>

#include "include/dart_api_dl.h"

emu::Api* __api_emu = nullptr;

namespace emu {

void Dart_SetReturnValue(Dart_NativeArguments args, Dart_Handle handle) {
  args->result = handle;
}

Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args, intptr_t n) {
  return args->args[n];
}

Dart_Handle Dart_GetNativeIntegerArgument(Dart_NativeArguments args,
                                          intptr_t n,
                                          int64_t* value) {
  return __api_emu->Dart_IntegerToInt64(args->args[n], value);
}

Dart_Handle Dart_NewInteger(int64_t value) {
  return __api_emu->Dart_NewInteger(value);
}

Dart_Handle Dart_GetNativeReceiver(Dart_NativeArguments args, intptr_t* peer) {
  Dart_Handle receiver = Dart_GetNativeArgument(args, 0);
  return __api_emu->Dart_GetPeer(receiver, peer);
}

Dart_Handle Dart_PropagateError(Dart_Handle error) {
  Dart_PropagateError_DL(reinterpret_cast<::Dart_Handle>(error));
  return nullptr;
}

bool Dart_IsError(Dart_Handle error) {
  return Dart_IsError_DL(reinterpret_cast<::Dart_Handle>(error));
}

Dart_Handle Dart_Null() {
  return __api_emu->Dart_Null();
}

struct FinalizerData {
  void* peer;
  void (*finalizer)(void*);

  ~FinalizerData() { finalizer(peer); }
};

void Dart_AttachFinalizer(Dart_Handle handle,
                          void* peer,
                          intptr_t native_size,
                          void (*finalizer)(void*)) {
  auto data = new FinalizerData{peer, finalizer};
  Dart_NewWeakPersistentHandle_DL(
      reinterpret_cast<::Dart_Handle>(handle), data, native_size,
      [](void* ignored1, ::Dart_WeakPersistentHandle ignored2, void* peer) {
        delete static_cast<FinalizerData*>(peer);
      });
}

}  // namespace emu
