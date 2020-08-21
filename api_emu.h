// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef API_EMU_H
#define API_EMU_H

#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <utility>

namespace emu {

struct __Dart_Handle;

typedef __Dart_Handle* Dart_Handle;

struct Api {
  Dart_Handle (*Dart_IntegerToInt64)(Dart_Handle handle, int64_t* value);
  Dart_Handle (*Dart_NewInteger)(int64_t value);
  Dart_Handle (*Dart_GetPeer)(Dart_Handle handle, intptr_t* peer);
  Dart_Handle (*Dart_SetPeer)(Dart_Handle handle, intptr_t);
  Dart_Handle (*Dart_NewObject0)(const char* cls, const char* ctor);
  Dart_Handle (*Dart_Null)();
};

typedef struct {
  uint32_t argc;
  Dart_Handle result;
  Dart_Handle args[10];  // Don't care about more than 10 args.
} NativeArguments, *Dart_NativeArguments;

typedef void (*Dart_NativeFunction)(Dart_NativeArguments);
typedef void* (*Dart_NativeFunctionTrampoline)();

Dart_Handle Dart_Null();

template <Dart_NativeFunction target>
void* TrampolineTo0() {
  NativeArguments args;
  args.argc = 0;
  args.result = nullptr;
  target(&args);
  if (args.result == nullptr) {
    return Dart_Null();
  }
  return args.result;
}

template <Dart_NativeFunction target>
void* TrampolineTo1(Dart_Handle arg0) {
  NativeArguments args;
  args.argc = 1;
  args.result = nullptr;
  args.args[0] = arg0;
  target(&args);
  if (args.result == nullptr) {
    return args.args[0];
  }
  return args.result;
}

template <Dart_NativeFunction target>
void* TrampolineTo2(Dart_Handle arg0, Dart_Handle arg1) {
  NativeArguments args;
  args.argc = 2;
  args.result = nullptr;
  args.args[0] = arg0;
  args.args[1] = arg1;
  target(&args);
  if (args.result == nullptr) {
    return args.args[0];
  }
  return args.result;
}

#define TRAMPOLINE_TO(Argc, F) \
  (Dart_NativeFunctionTrampoline)(TrampolineTo##Argc<F>)

void Dart_SetReturnValue(Dart_NativeArguments args, Dart_Handle handle);

Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args, intptr_t n);

Dart_Handle Dart_GetNativeIntegerArgument(Dart_NativeArguments args,
                                          intptr_t n,
                                          int64_t* value);

Dart_Handle Dart_NewInteger(int64_t value);

Dart_Handle Dart_GetNativeReceiver(Dart_NativeArguments args, intptr_t* peer);

Dart_Handle Dart_PropagateError(Dart_Handle error);

bool Dart_IsError(Dart_Handle error);

void Dart_AttachFinalizer(Dart_Handle handle,
                          void* peer,
                          intptr_t native_size,
                          void (*finalizer)(void*));

}  // namespace emu

extern "C" emu::Api* __api_emu;

#endif  // API_EMU_H