This repository illustrates how Dart VM C API (API) can be emulated using
`dart:ffi`, assuming that you want to forgo all benefits that `dart:ffi`
provides (e.g. performance) for the sake of reusing some C++ code which
was based on Dart VM C API.

**DISCLAIMER: This is by no means recommended way of using Dart FFI. In fact
this is a highly discouraged way to use Dart FFI because the code in this
repository uses a superior technology (FFI) to emulate worse technology (C API).
Recommended way is to build bindings in Dart FFI centric way.**

For illustrative purposes we bind a simple C++ class with two methods:

```cpp
class Counter {
 public:
  Counter();

  int64_t value();

  void increment(int64_t value);

 private:
  int64_t value_;
}
```

to a Dart class with a similar interface

```dart
class Counter {
  Counter();

  int get counter;

  void increment(int value);
}
```

using variety of methods:

* C API (`impl_api.{cc,dart}`);
* FFI (`impl_ffi.{cc,dart}`);
* C API emulation via FFI (`impl_api_emu.{cc,dart}`).

The idea behind C API emulation (`api_emu.{cc,h,dart}`) is to provide a layer
similar in structure to C API, but built on top of the FFI.

`test.dart` and `bench.dart` provides simple test and microbenchmarks
respectively.

Use `Makefile` to build native library.

The rest of this document discusses main principles of emulation of C API on
top of the FFI assuming that reader is familiar with both.

# C API vs FFI

The main difference between FFI and C API is that FFI is highly declarative
and static with respect to type signatures while C API is highly imperative and
reflective.

With FFI you declare how VM should unwrap Dart objects into native types on
the boundary, with C API you get an array of handles as an argument and then
you work with individual handles checking their type and unwrapping them
manually.

FFI does however provide a way to pass Dart objects as is without unwrapping
(though wrapped into handles) into native code. This works both when calling
C from Dart code but also when calling back.

```dart
// This function will be called from C but it can still throw an error.
Object callback(Object obj) {
  if (obj != "something") {
    throw "error";
  }
  return obj;
}

final callbackPtr =
  Pointer<NativeFunction<Handle Function(Handle)>>.fromFunction(callback)
final f = lib.lookupFunction<Handle Function(Handle),
                             Object Function(Object)>('f');
f("something", callback)
```

```cpp
Dart_Handle f(Dart_Handle obj, Dart_Handle (*callback)(Dart_Handle)) {
  // obj here would be a handle pointing to Dart String object representing
  // string "something".
  Dart_Handle result = callback(obj);

  // If callback throws an error it returns a handle containing an error
  // which can be detected and propagated using DL variant of Dart API.
  if (Dart_IsError_DL(result)) {
    Dart_PropagateError_DL(result);
  }

  return result;
}
```

Emulating Dart API surface through FFI is mostly built on top of this
capability and helper methods exposed through dynamically linked (DL) subset
of Dart API (`dart_api_dl.h`), which provides ways to work with
errors/exceptions, persistent and weak handles as well as ports for
asynchronous communication.

# Trivial cases

## `Dart_NativeFunction`

When binding functions via API we define them via very generic signature
`void (*)(Dart_NativeArguments arguments)`, while FFI expects specific
signatures. The simplest way to emulate this is to use a trampoline which
converts from one style to another, e.g. for a 2 argument function:

```cpp
// From api_emu.h
template <Dart_NativeFunction target>
void* TrampolineTo2(Dart_Handle arg0, Dart_Handle arg1) {
  NativeArguments args;
  args.argc = 2;
  args.result = nullptr;
  args.args[0] = arg0;
  args.args[1] = arg1;
  target(&args);
  if (args.result == nullptr) {
    return args.args[0];  // No fast way to return an null handle.
  }
  return args.result;
}

#define TRAMPOLINE_TO(Argc, F) \
  (Dart_NativeFunctionTrampoline)(TrampolineTo##Argc<F>)

// In impl_api_emu.cc
extern "C" FunctionLookup CounterLib_functions[] = {
  // ...
  {"ApiEmu_Counter_Increment", TRAMPOLINE_TO(2, ApiEmu_Counter_Increment)},
  // ...
};

static void ApiEmu_Counter_Allocate(Dart_NativeArguments args) {
  // Looks like API based function.
}
```

## Type checking, unwrapping/wrapping for fixed types

Dart C API has for example the following functions:

```cpp
Dart_Handle Dart_NewInteger(int64_t value);

bool Dart_IsInteger(Dart_Handle object);

Dart_Handle Dart_IntegerToInt64(Dart_Handle integer, int64_t* value);
```

FFI based shim for this functions would look like this:

```dart
// Native signature: Handle Function(Int64)
Object Dart_NewInteger(int value) {
  return value;
}

// Native signature: Int8 Function(Handle)
int Dart_IsInteger(Object object) {
  return object is int ? 1 : 0;
}

// Native signature: Handle Function(Handle, Pointer<Int64>)
Object Dart_IntegerToInt64(Object integer, Pointer<Int64> value) {
  value.value = integer as int;
  return true;
}
```

## Throwing errors

No shim is needed: use `Dart_PropagateError_DL(Dart_NewUnhandledExceptionError_DL(...))`.

## Invoking closures passed from Dart side

Simplest approach is something along the lines of:

```cpp
// C side of the shim
Dart_Handle Dart_InvokeClosure(Dart_Handle closure, int argc, Dart_Handle* argv) {
  switch (argc) {
    case 0: return Dart_InvokeClosureImpl0(closure);
    case 1: return Dart_InvokeClosureImpl1(closure, argv[0]);
    case 2: return Dart_InvokeClosureImpl2(closure, argv[0], argv[1]);
    case 3: return Dart_InvokeClosureImpl3(closure, argv[0], argv[2], argv[2]);
    // ...
  }
}
```

```dart
// Dart side of the shim
Object Dart_InvokeClosureImpl0(Object f) { return f(); }
Object Dart_InvokeClosureImpl1(Object f, Object arg0) { return f(arg0); }
```

Note: Dart does not support variadic functions and `dart:ffi` does not allow
unwrapping `Pointer<Handle>` so writing efficient generic implementation of
`Dart_InvokeClosureImpl` is impossible.

# Hard case: anything reflective.

Anything that requires reflective access to Dart program is impossible to
emulate via FFI because FFI by itself does not have such access. That includes
things like creating classes by class name, accessing fields by name, etc.

The only workaround for this is to make library that needs reflective access
to its members register information about those members in a globally
available dictionary.

For example for constructing objects:

```dart
// api_emu.dart
final _classes = <String, Map<String, Function>>{};

void registerClass(String name, Map<String, Function> ctors) {
  _classes[name] = ctors;
}

// Dart_Handle Dart_NewObject0(const char* class, const char* ctor)
Object _Dart_NewObject0(Pointer<Utf8> className, Pointer<Utf8> ctorName) {
  return _classes[Utf8.fromUtf8(className)][Utf8.fromUtf8(ctorName)]();
}

// counter implementation
void initializeLib() {
  registerClass('Counter', {
    '_construct': () => Counter._construct(),
  });
}
```

# Appendix: Performance

Going this route obviously means abandoning all FFI benefits:

```
NopApiCall(RunTime): 0.4483463529378007 us.
NopFfiCall(RunTime): 0.38423919966048625 us.
NopApiEmuCall(RunTime): 1.1852757929346895 us.
CounterViaApi(RunTime): 148.97750465549348 us.
CounterViaApiWithPeer(RunTime): 212.0293649952295 us.
CounterViaFfi(RunTime): 33.624552378070305 us.
CounterViaApiEmu(RunTime): 297.3048454221165 us.
CounterAllocateViaApi(RunTime): 4.215829157910047 us.
CounterAllocateViaFfi(RunTime): 3.2318121310336845 us.
CounterAllocateViaApiEmu(RunTime): 19.987857406981743 us.
```

FFI does seem to have some performance problems however, as we were writing
benchmarks we discovered that some cases are not yet optimized as expected.

```
CounterViaFfiRaw(RunTime): 1379.2164024810475 us.
CounterViaFfiRawRaw(RunTime): 31.568526556704285 us.
```

These numbers should be considerably lower (and equal).
[Issue to track](https://github.com/dart-lang/sdk/issues/43142)
