#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "counter.h"
#include "include/dart_api.h"
#include "include/dart_native_api.h"

Dart_Handle HandleError(Dart_Handle handle) {
  if (Dart_IsError(handle)) {
    Dart_PropagateError(handle);
  }
  return handle;
}

static void Api_Nop(Dart_NativeArguments args) {
    // Do nothing.
}

Dart_Handle counter_type, counter_with_peer_type;

template<typename T>
T* Self(Dart_NativeArguments args) {
    intptr_t ptr;
    HandleError(Dart_GetNativeReceiver(args, &ptr));
    return reinterpret_cast<T*>(ptr);
}

DART_EXPORT void FinalizeCounter(void* isolate_callback_data, Dart_WeakPersistentHandle handle, void* peer) {
  delete reinterpret_cast<Counter*>(peer);
}

static void Api_Counter_Allocate(Dart_NativeArguments args) {
  auto counter = new Counter();

  intptr_t native_fields[] = {reinterpret_cast<intptr_t>(counter)};
  Dart_Handle result = HandleError(Dart_AllocateWithNativeFields(counter_type, 1, native_fields));
  Dart_NewWeakPersistentHandle(result, counter, sizeof(Counter), FinalizeCounter);
  Dart_SetReturnValue(args, result);
}

static void Api_Counter_GetValue(Dart_NativeArguments args) {
  auto self = Self<Counter>(args);
  Dart_SetReturnValue(args, HandleError(Dart_NewInteger(self->value())));
}

static void Api_Counter_Increment(Dart_NativeArguments args) {
  auto self = Self<Counter>(args);
  int64_t value;
  HandleError(Dart_GetNativeIntegerArgument(args, 1, &value));
  self->increment(value);
}

template<typename T>
T* SelfFromPeer(Dart_NativeArguments args) {
    void* peer;
    HandleError(Dart_GetPeer(Dart_GetNativeArgument(args, 0), &peer));
    return reinterpret_cast<T*>(peer);
}

static void Api_CounterWithPeer_Allocate(Dart_NativeArguments args) {
  auto counter = new Counter();
  Dart_Handle result = HandleError(Dart_Allocate(counter_with_peer_type));
  HandleError(Dart_SetPeer(result, counter));
  Dart_NewWeakPersistentHandle(result, counter, sizeof(Counter), FinalizeCounter);
  Dart_SetReturnValue(args, result);
}

static void Api_CounterWithPeer_GetValue(Dart_NativeArguments args) {
  auto self = SelfFromPeer<Counter>(args);
  Dart_SetReturnValue(args, HandleError(Dart_NewInteger(self->value())));
}

static void Api_CounterWithPeer_Increment(Dart_NativeArguments args) {
  auto self = SelfFromPeer<Counter>(args);
  int64_t value;
  HandleError(Dart_GetNativeIntegerArgument(args, 1, &value));
  self->increment(value);
}

Dart_NativeFunction ResolveName(Dart_Handle name,
                                int argc,
                                bool* auto_setup_scope);


DART_EXPORT Dart_Handle impl_Init(Dart_Handle parent_library) {
  if (Dart_IsError(parent_library)) {
    return parent_library;
  }

  Dart_Handle result_code =
      Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if (Dart_IsError(result_code)) {
    return result_code;
  }

  counter_type = Dart_NewPersistentHandle(
    HandleError(Dart_GetType(parent_library,
                             Dart_NewStringFromCString("Counter"),
                             0,
                             nullptr)));
  counter_with_peer_type = Dart_NewPersistentHandle(
    HandleError(Dart_GetType(parent_library,
                             Dart_NewStringFromCString("CounterWithPeer"),
                             0,
                             nullptr)));



  return Dart_Null();
}

struct FunctionLookup {
  const char* name;
  Dart_NativeFunction function;
};

FunctionLookup function_list[] = {
    {"Api_Counter_Allocate", &Api_Counter_Allocate},
    {"Api_Counter_GetValue", &Api_Counter_GetValue},
    {"Api_Counter_Increment", &Api_Counter_Increment},
    {"Api_CounterWithPeer_Allocate", &Api_CounterWithPeer_Allocate},
    {"Api_CounterWithPeer_GetValue", &Api_CounterWithPeer_GetValue},
    {"Api_CounterWithPeer_Increment", &Api_CounterWithPeer_Increment},
    {"Test_Counter_GetAllocatedCount", [](Dart_NativeArguments args) { Dart_SetReturnValue(args, Dart_NewInteger(Counter::num_allocated)); }},
  {NULL, NULL}
};

FunctionLookup no_scope_function_list[] = {
    {"nop", &Api_Nop},
    {NULL, NULL}
};

Dart_NativeFunction ResolveName(Dart_Handle name,
                                int argc,
                                bool* auto_setup_scope) {
  if (!Dart_IsString(name)) {
    return NULL;
  }
  Dart_NativeFunction result = NULL;
  if (auto_setup_scope == NULL) {
    return NULL;
  }

  Dart_EnterScope();
  const char* cname;
  HandleError(Dart_StringToCString(name, &cname));

  for (int i=0; function_list[i].name != NULL; ++i) {
    if (strcmp(function_list[i].name, cname) == 0) {
      *auto_setup_scope = true;
      result = function_list[i].function;
      break;
    }
  }

  if (result != NULL) {
    Dart_ExitScope();
    return result;
  }

  for (int i=0; no_scope_function_list[i].name != NULL; ++i) {
    if (strcmp(no_scope_function_list[i].name, cname) == 0) {
      *auto_setup_scope = false;
      result = no_scope_function_list[i].function;
      break;
    }
  }

  Dart_ExitScope();
  return result;
}