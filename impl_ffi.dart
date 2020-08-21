// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

final lib = ffi.DynamicLibrary.open('libimpl.so');

final nop = lib.lookupFunction<ffi.Void Function(), void Function()>('ffi_Nop');

class _DartEntry extends ffi.Struct {
  ffi.Pointer<ffi.Int8> name;
  ffi.Pointer<ffi.Void> function;
}

class _DartApi extends ffi.Struct {
  @ffi.Int32()
  int major;
  @ffi.Int32()
  int minor;
  ffi.Pointer<_DartEntry> functions;
}

class _Counter extends ffi.Struct {
  @ffi.Int64()
  int counter;
}

class Counter {
  final ffi.Pointer<_Counter> _impl;
  static final _sizeInBytes = ffi.sizeOf<_Counter>();

  Counter() : _impl = _allocate() {
    newWeakPersistentHandle(this, _impl.cast(), _sizeInBytes, _finalizeCounter);
  }

  int get rawCounter => _impl.ref.counter;

  void rawIncrement(int value) {
    _impl.ref.counter += value;
  }

  int get rawrawCounter => _impl.cast<ffi.Int64>().value;

  void rawrawIncrement(int value) {
    _impl.cast<ffi.Int64>().value += value;
  }

  int get counter => _getValue(_impl);

  void increment(int value) => _increment(_impl, value);

  static final _allocate = lib.lookupFunction<ffi.Pointer<_Counter> Function(),
      ffi.Pointer<_Counter> Function()>('ffi_Counter_Allocate');
  static final _free = lib.lookupFunction<
      ffi.Void Function(ffi.Pointer<_Counter>),
      void Function(ffi.Pointer<_Counter>)>('ffi_Counter_Allocate');
  static final _getValue = lib.lookupFunction<
      ffi.Int64 Function(ffi.Pointer<_Counter>),
      int Function(ffi.Pointer<_Counter>)>('ffi_Counter_GetValue');
  static final _increment = lib.lookupFunction<
      ffi.Void Function(ffi.Pointer<_Counter>, ffi.Int64),
      void Function(ffi.Pointer<_Counter>, int)>('ffi_Counter_Increment');

  static final _finalizeCounter =
      lib.lookup<ffi.NativeFunction<Dart_WeakPersistentHandleFinalizer_Type>>(
          'FinalizeCounter');
}

typedef Dart_WeakPersistentHandleFinalizer_Type = ffi.Void Function(
    ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>);
typedef Dart_WeakPersistentHandleFinalizer_DartType = void Function(
    ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>);
typedef Dart_NewWeakPersistentHandle_Type = ffi.Pointer<ffi.Void> Function(
    ffi.Handle,
    ffi.Pointer<ffi.Void>,
    ffi.IntPtr,
    ffi.Pointer<ffi.NativeFunction<Dart_WeakPersistentHandleFinalizer_Type>>);
typedef Dart_NewWeakPersistentHandle_DartType = ffi.Pointer<ffi.Void> Function(
    Object,
    ffi.Pointer<ffi.Void>,
    int,
    ffi.Pointer<ffi.NativeFunction<Dart_WeakPersistentHandleFinalizer_Type>>);

final newWeakPersistentHandle = () {
  final ffi.Pointer<_DartApi> dlapi = ffi.NativeApi.initializeApiDLData.cast();
  for (int i = 0;
      dlapi.ref.functions.elementAt(i).ref.name != ffi.nullptr;
      i++) {
    final name =
        Utf8.fromUtf8(dlapi.ref.functions.elementAt(i).ref.name.cast<Utf8>());
    if (name == 'Dart_NewWeakPersistentHandle') {
      return dlapi.ref.functions
          .elementAt(i)
          .ref
          .function
          .cast<ffi.NativeFunction<Dart_NewWeakPersistentHandle_Type>>()
          .asFunction<Dart_NewWeakPersistentHandle_DartType>();
    }
  }
}();
