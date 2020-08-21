// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef NT_Dart_IntegerToInt64 = Handle Function(Handle, Pointer<Int64>);
typedef NT_Dart_NewInteger = Handle Function(Int64);
typedef NT_Dart_GetPeer = Handle Function(Handle, Pointer<Pointer<Void>>);
typedef NT_Dart_SetPeer = Handle Function(Handle, Pointer<Void>);
typedef NT_Dart_NewObject0 = Handle Function(Pointer<Utf8>, Pointer<Utf8>);
typedef NT_Dart_Null = Handle Function();

class Api extends Struct {
  Pointer<NativeFunction<NT_Dart_IntegerToInt64>> Dart_IntegerToInt64;
  Pointer<NativeFunction<NT_Dart_NewInteger>> Dart_NewInteger;
  Pointer<NativeFunction<NT_Dart_GetPeer>> Dart_GetPeer;
  Pointer<NativeFunction<NT_Dart_SetPeer>> Dart_SetPeer;
  Pointer<NativeFunction<NT_Dart_NewObject0>> Dart_NewObject0;
  Pointer<NativeFunction<NT_Dart_Null>> Dart_Null;
}

Object _Dart_IntegerToInt64(Object obj, Pointer<Int64> value) {
  value.value = obj as int;
  return true;
}

Object _Dart_NewInteger(int value) {
  return value;
}

Object _Dart_GetPeer(Object obj, Pointer<Pointer<Void>> peer) {
  peer.value = (obj as NativeWrapper)._peer;
  return true;
}

Object _Dart_SetPeer(Object obj, Pointer<Void> peer) {
  (obj as NativeWrapper)._peer = peer;
  return true;
}

bool _initialized = false;

void initialize() {
  if (!_initialized) {
    final api = allocate<Api>();
    api.ref
      ..Dart_GetPeer = Pointer.fromFunction<NT_Dart_GetPeer>(_Dart_GetPeer)
      ..Dart_SetPeer = Pointer.fromFunction<NT_Dart_SetPeer>(_Dart_SetPeer)
      ..Dart_IntegerToInt64 =
          Pointer.fromFunction<NT_Dart_IntegerToInt64>(_Dart_IntegerToInt64)
      ..Dart_NewInteger =
          Pointer.fromFunction<NT_Dart_NewInteger>(_Dart_NewInteger)
      ..Dart_NewObject0 =
          Pointer.fromFunction<NT_Dart_NewObject0>(_Dart_NewObject0)
      ..Dart_Null = Pointer.fromFunction<NT_Dart_Null>(_Dart_Null);

    final lib = DynamicLibrary.open('libimpl.so');

    lib.lookup('__api_emu').cast<Pointer<Api>>().value = api;

    final initializeApi = lib.lookupFunction<IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)>("Dart_InitializeApiDL");
    if (initializeApi(NativeApi.initializeApiDLData) != 0) {
      throw "Failed to initialize Dart API";
    }

    _initialized = true;
  }
}

class NativeWrapper {
  Pointer<Void> _peer;
}

class FunctionLookup extends Struct {
  Pointer<Utf8> name;
  Pointer<Void> function;
}

typedef F0 = Object Function();
typedef F1 = Object Function(Object);
typedef F2 = Object Function(Object, Object);

typedef _NF0 = Handle Function();
typedef _NF1 = Handle Function(Handle);
typedef _NF2 = Handle Function(Handle, Handle);

class NativeResolver {
  final String libraryName;
  final Pointer<FunctionLookup> _list;

  NativeResolver(this.libraryName, String soName)
      : _list = DynamicLibrary.open(soName)
            .lookup<FunctionLookup>('${libraryName}_functions');

  Pointer<Void> _resolve(String name) {
    for (int i = 0; _list.elementAt(i).ref.name != nullptr; i++) {
      if (Utf8.fromUtf8(_list.elementAt(i).ref.name) == name) {
        return _list.elementAt(i).ref.function;
      }
    }
    throw 'Failed to resolve ${name} in ${libraryName}';
  }

  F0 resolve0(String name) {
    return _resolve(name).cast<NativeFunction<_NF0>>().asFunction<F0>();
  }

  F1 resolve1(String name) {
    return _resolve(name).cast<NativeFunction<_NF1>>().asFunction<F1>();
  }

  F2 resolve2(String name) {
    return _resolve(name).cast<NativeFunction<_NF2>>().asFunction<F2>();
  }
}

final _classes = <String, Map<String, Function>>{};

void registerClass(String name, Map<String, Function> ctors) {
  _classes[name] = ctors;
}

Object _Dart_NewObject0(Pointer<Utf8> clsNameUtf8, Pointer<Utf8> ctorNameUtf8) {
  final clsName = Utf8.fromUtf8(clsNameUtf8);
  final ctorName = Utf8.fromUtf8(ctorNameUtf8);

  final cls = _classes[clsName];
  if (cls == null) {
    throw 'Unknown class ${clsName}';
  }

  final ctor = cls[ctorName];
  if (ctor == null) {
    throw 'Class ${clsName} has no constructor ${ctorName}';
  }

  return ctor();
}

Object _Dart_Null() => null;
