// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';

import 'impl_api.dart' as impl_api;
import 'impl_api_emu.dart' as impl_api_emu;
import 'impl_ffi.dart' as impl_ffi;

class NopApiCall extends BenchmarkBase {
  NopApiCall() : super('NopApiCall');

  @override
  void run() {
    impl_api.nop();
  }
}

class NopFfiCall extends BenchmarkBase {
  NopFfiCall() : super('NopFfiCall');

  @override
  void run() {
    impl_ffi.nop();
  }
}

class NopApiEmuCall extends BenchmarkBase {
  NopApiEmuCall() : super('NopApiEmuCall');

  @override
  void run() {
    impl_api_emu.nop();
  }
}

class CounterViaApi extends BenchmarkBase {
  CounterViaApi() : super('CounterViaApi');

  @override
  void run() {
    final c = impl_api.Counter();
    for (var i = 0; i < 100; i++) {
      c.increment(i);
    }
    if (c.counter != 99 * 50) {
      throw 'error';
    }
  }
}

class CounterViaApiWithPeer extends BenchmarkBase {
  CounterViaApiWithPeer() : super('CounterViaApiWithPeer');

  @override
  void run() {
    final c = impl_api.CounterWithPeer();
    for (var i = 0; i < 100; i++) {
      c.increment(i);
    }
    if (c.counter != 99 * 50) {
      throw 'error';
    }
  }
}

class CounterViaFfi extends BenchmarkBase {
  CounterViaFfi() : super('CounterViaFfi');

  @override
  void run() {
    final c = impl_ffi.Counter();
    for (var i = 0; i < 100; i++) {
      c.increment(i);
    }
    if (c.counter != 99 * 50) {
      throw 'error';
    }
  }
}

class CounterViaFfiRaw extends BenchmarkBase {
  CounterViaFfiRaw() : super('CounterViaFfiRaw');

  @override
  void run() {
    final c = impl_ffi.Counter();
    for (var i = 0; i < 100; i++) {
      c.rawIncrement(i);
    }
    if (c.rawCounter != 99 * 50) {
      throw 'error';
    }
  }
}

class CounterViaFfiRawRaw extends BenchmarkBase {
  CounterViaFfiRawRaw() : super('CounterViaFfiRawRaw');

  @override
  void run() {
    final c = impl_ffi.Counter();
    for (var i = 0; i < 100; i++) {
      c.rawrawIncrement(i);
    }
    if (c.rawrawCounter != 99 * 50) {
      throw 'error';
    }
  }
}

class CounterViaApiEmu extends BenchmarkBase {
  CounterViaApiEmu() : super('CounterViaApiEmu') {
    impl_api_emu.initializeLib();
  }

  @override
  void run() {
    final c = impl_api_emu.Counter();
    for (var i = 0; i < 100; i++) {
      c.increment(i);
    }
    if (c.counter != 99 * 50) {
      throw 'error';
    }
  }
}

class CounterAllocateViaApiEmu extends BenchmarkBase {
  CounterAllocateViaApiEmu() : super('CounterAllocateViaApiEmu') {
    impl_api_emu.initializeLib();
  }

  @override
  void run() {
    impl_api_emu.Counter();
  }
}

class CounterAllocateViaApi extends BenchmarkBase {
  CounterAllocateViaApi() : super('CounterAllocateViaApi');

  @override
  void run() {
    impl_api.Counter();
  }
}

class CounterAllocateViaFfi extends BenchmarkBase {
  CounterAllocateViaFfi() : super('CounterAllocateViaFfi');

  @override
  void run() {
    impl_ffi.Counter();
  }
}

// Dart VM Extensions don't work in AOT mode. To make this file runnable
// after dart2native compilation exclude API benchmarks in product mode.
const bool isProduct = const bool.fromEnvironment('dart.vm.product');

final allBenchmarks = [
  if (!isProduct) NopApiCall(),
  NopFfiCall(),
  NopApiEmuCall(),
  if (!isProduct) CounterViaApi(),
  if (!isProduct) CounterViaApiWithPeer(),
  CounterViaFfi(),
  CounterViaFfiRaw(),
  CounterViaFfiRawRaw(),
  CounterViaApiEmu(),
  if (!isProduct) CounterAllocateViaApi(),
  CounterAllocateViaFfi(),
  CounterAllocateViaApiEmu(),
];

void main(List<String> args) {
  bool isInteresting(BenchmarkBase benchmark) {
    return args.length > 0 ? benchmark.name.contains(args[0]) : true;
  }

  final benchmarks = allBenchmarks.where(isInteresting).toList();
  print(benchmarks.map((e) => e.name).toList());

  for (var b in benchmarks) {
    b.warmup();
  }

  for (var b in benchmarks) {
    b.report();
  }
}
